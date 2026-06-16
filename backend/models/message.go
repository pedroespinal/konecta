package models

// PayloadType es el tipo de paquete en el wire protocol.
type PayloadType int

const (
	PayloadMessage      PayloadType = 0
	PayloadMessageAck   PayloadType = 1
	PayloadPreKeyBundle PayloadType = 2
	PayloadPresence     PayloadType = 3
	PayloadTyping       PayloadType = 4
	PayloadReadReceipt  PayloadType = 5
	PayloadPing         PayloadType = 6
	PayloadPong         PayloadType = 7
	// Fase 4: señalización WebRTC
	PayloadCallInvite   PayloadType = 8
	PayloadCallAccept   PayloadType = 9
	PayloadCallReject   PayloadType = 10
	PayloadCallEnd      PayloadType = 11
	PayloadSdpOffer     PayloadType = 12
	PayloadSdpAnswer    PayloadType = 13
	PayloadIceCandidate PayloadType = 14
)

// Envelope es el sobre generico de todos los mensajes.
// El servidor NO descifra el campo Ciphertext — solo enruta.
type Envelope struct {
	Type      PayloadType    `json:"type"`
	From      string         `json:"from,omitempty"`
	To        string         `json:"to,omitempty"`
	Ciphertext string        `json:"ciphertext,omitempty"`
	MessageID  string        `json:"messageId,omitempty"`
	Timestamp  int64         `json:"timestamp,omitempty"`
	IsOnline   *bool         `json:"isOnline,omitempty"`
	LastSeen   *int64        `json:"lastSeen,omitempty"`
	IsTyping   *bool         `json:"isTyping,omitempty"`
	ChatID     string        `json:"chatId,omitempty"`
}
