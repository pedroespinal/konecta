package fcm

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var msgClient *messaging.Client

// Init inicializa el cliente Firebase Admin desde la variable de entorno
// FIREBASE_SERVICE_ACCOUNT (JSON del service account de Firebase).
// Si la variable no está configurada, el push queda desactivado silenciosamente.
func Init() {
	cred := os.Getenv("FIREBASE_SERVICE_ACCOUNT")
	if cred == "" {
		log.Println("[FCM] FIREBASE_SERVICE_ACCOUNT no configurado — push desactivado")
		return
	}
	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsJSON([]byte(cred)))
	if err != nil {
		log.Printf("[FCM] error inicializando Firebase: %v", err)
		return
	}
	c, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("[FCM] error obteniendo cliente Messaging: %v", err)
		return
	}
	msgClient = c
	log.Println("[FCM] Firebase Admin inicializado")
}

// Send envía una notificación push al token dado con datos adjuntos.
// Es silencioso (no devuelve error) para no bloquear el relay.
func Send(fcmToken, title, body string, data map[string]string) {
	if msgClient == nil || fcmToken == "" {
		return
	}
	msg := &messaging.Message{
		Token: fcmToken,
		Data:  data,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Title:       title,
				Body:        body,
				ChannelID:   "konecta_messages",
				Priority:    messaging.PriorityHigh,
				DefaultSound: true,
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{"apns-priority": "10"},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{Title: title, Body: body},
					Sound: "default",
				},
			},
		},
	}
	if _, err := msgClient.Send(context.Background(), msg); err != nil {
		log.Printf("[FCM] error enviando push a token ...%s: %v",
			safeToken(fcmToken), err)
	}
}

func safeToken(t string) string {
	if len(t) > 8 {
		return t[len(t)-8:]
	}
	return t
}
