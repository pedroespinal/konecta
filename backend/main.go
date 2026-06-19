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

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","service":"konecta-relay"}`))
	})

	log.Printf("Konecta relay iniciando en :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("error: %v", err)
	}
}
