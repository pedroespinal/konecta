package relay

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"

	"github.com/pedroespinal/konecta-relay/fcm"
	"github.com/pedroespinal/konecta-relay/models"
)

type routeMsg struct {
	to   string
	data []byte
	from *Client
}

// Hub gestiona el registro de clientes y el enrutamiento de mensajes.
// Nunca almacena mensajes ni descifra ciphertext — solo reenvía.
type Hub struct {
	mu         sync.RWMutex
	clients    map[string]*Client
	fcmTokens  map[string][]string      // userID -> lista de tokens FCM (múltiples dispositivos)
	publicKeys map[string]json.RawMessage
	register   chan *Client
	unregister chan *Client
	route      chan routeMsg
}

func NewHub() *Hub {
	h := &Hub{
		clients:    make(map[string]*Client),
		fcmTokens:  make(map[string][]string),
		publicKeys: make(map[string]json.RawMessage),
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
		route:      make(chan routeMsg, 1024),
	}
	h.loadTokens()
	return h
}

func (h *Hub) Run() {
	for {
		select {
		case c := <-h.register:
			h.mu.Lock()
			h.clients[c.userID] = c
			if c.fcmToken != "" {
				h.fcmTokens[c.userID] = addUniqueToken(h.fcmTokens[c.userID], c.fcmToken)
			}
			h.mu.Unlock()
			if c.fcmToken != "" {
				h.saveTokens()
			}
			log.Printf("connected: %s  total=%d", c.userID, h.clientCount())
			h.broadcastPresence(c.userID, true)

		case c := <-h.unregister:
			h.mu.Lock()
			if existing, ok := h.clients[c.userID]; ok && existing == c {
				delete(h.clients, c.userID)
				close(c.send)
			}
			h.mu.Unlock()
			log.Printf("disconnected: %s  total=%d", c.userID, h.clientCount())
			h.broadcastPresence(c.userID, false)

		case msg := <-h.route:
			h.mu.RLock()
			dest, ok := h.clients[msg.to]
			h.mu.RUnlock()

			if ok {
				select {
				case dest.send <- msg.data:
					ack, _ := json.Marshal(models.Envelope{
						Type:      models.PayloadMessageAck,
						MessageID: extractMessageID(msg.data),
					})
					select {
					case msg.from.send <- ack:
					default:
					}
				default:
					log.Printf("buffer lleno para %s", msg.to)
				}
			} else {
				// Destinatario offline — enviar FCM push a todos sus dispositivos
				h.pushOfflineMessage(msg.to, msg.data)
			}
		}
	}
}

// HandleRegisterToken registra el FCM token de un dispositivo via HTTP POST /register-token.
// Admite múltiples tokens por usuario (múltiples dispositivos).
func (h *Hub) HandleRegisterToken(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		UserID   string `json:"userId"`
		FCMToken string `json:"fcmToken"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.UserID == "" || req.FCMToken == "" {
		http.Error(w, "invalid request: userId y fcmToken requeridos", http.StatusBadRequest)
		return
	}
	h.mu.Lock()
	h.fcmTokens[req.UserID] = addUniqueToken(h.fcmTokens[req.UserID], req.FCMToken)
	h.mu.Unlock()
	h.saveTokens()
	log.Printf("[FCM] token registrado via HTTP para %s (total tokens: %d)",
		req.UserID, len(h.fcmTokens[req.UserID]))
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"ok":true}`))
}

// pushOfflineMessage envía un FCM push a TODOS los dispositivos del destinatario offline.
func (h *Hub) pushOfflineMessage(userID string, data []byte) {
	h.mu.RLock()
	tokens := make([]string, len(h.fcmTokens[userID]))
	copy(tokens, h.fcmTokens[userID])
	h.mu.RUnlock()

	if len(tokens) == 0 {
		return
	}

	var env models.Envelope
	if err := json.Unmarshal(data, &env); err != nil {
		return
	}
	if env.Type != models.PayloadMessage {
		return
	}
	pushData := map[string]string{
		"type":       strconv.Itoa(int(models.PayloadMessage)),
		"chatId":     env.ChatID,
		"from":       env.From,
		"ciphertext": env.Ciphertext,
		"messageId":  env.MessageID,
		"timestamp":  strconv.FormatInt(env.Timestamp, 10),
	}

	for _, token := range tokens {
		token := token
		go func() {
			invalid := fcm.Send(token, "Konecta", "Tienes un mensaje nuevo", pushData)
			if invalid {
				h.removeToken(userID, token)
			}
		}()
	}
}

// removeToken elimina un token FCM inválido de la lista del usuario.
func (h *Hub) removeToken(userID, token string) {
	h.mu.Lock()
	list := h.fcmTokens[userID]
	newList := list[:0]
	for _, t := range list {
		if t != token {
			newList = append(newList, t)
		}
	}
	if len(newList) == 0 {
		delete(h.fcmTokens, userID)
	} else {
		h.fcmTokens[userID] = newList
	}
	h.mu.Unlock()
	h.saveTokens()
	log.Printf("[FCM] token inválido eliminado para %s", userID)
}

// addUniqueToken agrega token a la lista solo si no existe ya.
func addUniqueToken(tokens []string, token string) []string {
	for _, t := range tokens {
		if t == token {
			return tokens
		}
	}
	return append(tokens, token)
}

// ── Persistencia de tokens FCM ────────────────────────────────────────────────
// Los tokens se guardan en un archivo JSON para sobrevivir reinicios del proceso.
// La ruta se configura con la variable TOKENS_FILE; por defecto /tmp/fcm_tokens.json.

func tokensFilePath() string {
	if p := os.Getenv("TOKENS_FILE"); p != "" {
		return p
	}
	return "/tmp/fcm_tokens.json"
}

func (h *Hub) loadTokens() {
	path := tokensFilePath()
	data, err := os.ReadFile(path)
	if err != nil {
		return // archivo no existe aún, ok
	}
	var tokens map[string][]string
	if err := json.Unmarshal(data, &tokens); err != nil {
		log.Printf("[FCM] error cargando tokens: %v", err)
		return
	}
	h.mu.Lock()
	h.fcmTokens = tokens
	h.mu.Unlock()
	total := 0
	for _, v := range tokens {
		total += len(v)
	}
	log.Printf("[FCM] %d tokens cargados para %d usuarios", total, len(tokens))
}

func (h *Hub) saveTokens() {
	h.mu.RLock()
	data, err := json.Marshal(h.fcmTokens)
	h.mu.RUnlock()
	if err != nil {
		return
	}
	if err := os.WriteFile(tokensFilePath(), data, 0644); err != nil {
		log.Printf("[FCM] error guardando tokens: %v", err)
	}
}

// ── Presencia y claves públicas ───────────────────────────────────────────────

func (h *Hub) clientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

func (h *Hub) broadcastPresence(userID string, online bool) {
	msg, _ := json.Marshal(models.Envelope{
		Type:     models.PayloadPresence,
		From:     userID,
		IsOnline: &online,
	})
	h.mu.RLock()
	defer h.mu.RUnlock()
	for uid, c := range h.clients {
		if uid != userID {
			select {
			case c.send <- msg:
			default:
			}
		}
	}
}

func (h *Hub) HandlePublishKeys(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var bundle json.RawMessage
	if err := json.NewDecoder(r.Body).Decode(&bundle); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	var meta struct {
		UserID string `json:"userId"`
	}
	if err := json.Unmarshal(bundle, &meta); err != nil || meta.UserID == "" {
		http.Error(w, "missing userId in bundle", http.StatusBadRequest)
		return
	}
	h.mu.Lock()
	h.publicKeys[meta.UserID] = bundle
	h.mu.Unlock()
	log.Printf("[KEYS] bundle publicado para %s", meta.UserID)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"ok":true}`))
}

func (h *Hub) HandleGetKeys(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID := strings.TrimPrefix(r.URL.Path, "/keys/")
	if userID == "" {
		http.Error(w, "userId requerido", http.StatusBadRequest)
		return
	}
	h.mu.RLock()
	bundle, ok := h.publicKeys[userID]
	h.mu.RUnlock()
	if !ok {
		http.Error(w, "keys not found", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(bundle)
}

func extractMessageID(data []byte) string {
	var env models.Envelope
	if err := json.Unmarshal(data, &env); err != nil {
		return ""
	}
	return env.MessageID
}
