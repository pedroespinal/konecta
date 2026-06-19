package relay

import (
	"encoding/json"
	"log"
	"strconv"
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
	clients    map[string]*Client // userID -> Client activo
	fcmTokens  map[string]string  // userID -> FCM token (persiste tras desconexión)
	register   chan *Client
	unregister chan *Client
	route      chan routeMsg
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		fcmTokens:  make(map[string]string),
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
		route:      make(chan routeMsg, 1024),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case c := <-h.register:
			h.mu.Lock()
			h.clients[c.userID] = c
			if c.fcmToken != "" {
				h.fcmTokens[c.userID] = c.fcmToken
			}
			h.mu.Unlock()
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
			fcmToken := h.fcmTokens[msg.to]
			h.mu.RUnlock()

			if ok {
				select {
				case dest.send <- msg.data:
					// Ack al emisor
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
				// Destinatario offline — enviar FCM push si hay token
				h.pushOfflineMessage(fcmToken, msg.data)
			}
		}
	}
}

// pushOfflineMessage envía un FCM push cuando el destinatario no está conectado.
// Solo actúa para mensajes de texto (PayloadMessage).
func (h *Hub) pushOfflineMessage(fcmToken string, data []byte) {
	if fcmToken == "" {
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
	go fcm.Send(fcmToken, "Konecta", "Tienes un mensaje nuevo", pushData)
}

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

func extractMessageID(data []byte) string {
	var env models.Envelope
	if err := json.Unmarshal(data, &env); err != nil {
		return ""
	}
	return env.MessageID
}
