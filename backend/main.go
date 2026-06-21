package main

import (
	"log"
	"net/http"
	"os"

	"github.com/pedroespinal/konecta-relay/fcm"
	"github.com/pedroespinal/konecta-relay/relay"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Inicializar FCM (sin-op si FIREBASE_SERVICE_ACCOUNT no está configurado)
	fcm.Init()

	hub := relay.NewHub()
	go hub.Run()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		relay.ServeWS(hub, w, r)
	})

	// Registro de FCM token via HTTP — independiente del WebSocket.
	// Flutter llama este endpoint al iniciar para garantizar que el relay
	// tenga el token aunque el WebSocket no esté conectado o el relay haya reiniciado.
	http.HandleFunc("/register-token", hub.HandleRegisterToken)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","service":"konecta-relay"}`))
	})

	log.Printf("Konecta relay iniciando en :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("error: %v", err)
	}
}
