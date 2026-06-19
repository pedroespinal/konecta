package relay

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"github.com/pedroespinal/konecta-relay/models"
)

const (
	writeTimeout = 10 * time.Second
	pongTimeout  = 60 * time.Second
	pingInterval = 25 * time.Second
	maxMsgSize   = 65536
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// Client representa una conexión WebSocket activa.
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte
	userID   string
	fcmToken string // token FCM del dispositivo, puede estar vacío
}

// ServeWS actualiza la conexión HTTP a WebSocket y registra el cliente en el hub.
// Parámetros de query esperados: userId (requerido), fcmToken (opcional).
func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userId")
	if userID == "" {
		http.Error(w, "userId requerido", http.StatusBadRequest)
		return
	}
	fcmToken := r.URL.Query().Get("fcmToken")

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("upgrade error: %v", err)
		return
	}

	c := &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan []byte, 256),
		userID:   userID,
		fcmToken: fcmToken,
	}
	hub.register <- c

	go c.writePump()
	go c.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMsgSize)
	c.conn.SetReadDeadline(time.Now().Add(pongTimeout))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongTimeout))
		return nil
	})

	for {
		_, raw, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway,
				websocket.CloseAbnormalClosure) {
				log.Printf("ws error [%s]: %v", c.userID, err)
			}
			break
		}

		var env models.Envelope
		if err := json.Unmarshal(raw, &env); err != nil {
			continue
		}

		switch env.Type {
		case models.PayloadPing:
			pong, _ := json.Marshal(models.Envelope{Type: models.PayloadPong})
			c.send <- pong

		case models.PayloadMessage, models.PayloadPreKeyBundle:
			env.From = c.userID
			out, _ := json.Marshal(env)
			c.hub.route <- routeMsg{to: env.To, data: out, from: c}

		case models.PayloadTyping, models.PayloadReadReceipt:
			env.From = c.userID
			out, _ := json.Marshal(env)
			c.hub.route <- routeMsg{to: env.To, data: out, from: c}

		case models.PayloadCallInvite, models.PayloadCallAccept,
			models.PayloadCallReject, models.PayloadCallEnd,
			models.PayloadSdpOffer, models.PayloadSdpAnswer,
			models.PayloadIceCandidate:
			env.From = c.userID
			out, _ := json.Marshal(env)
			c.hub.route <- routeMsg{to: env.To, data: out, from: c}

		default:
			// Tipo desconocido — ignorar
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingInterval)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeTimeout))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, nil)
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeTimeout))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
