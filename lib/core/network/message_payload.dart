import 'dart:convert';

// Formato de mensajes en el cable (relay server)
// Todo va cifrado — el servidor ve el sobre pero no el contenido
enum PayloadType {
  message,
  messageAck,
  preKeyBundle,
  presenceUpdate,
  typingIndicator,
  readReceipt,
  ping,
  pong,
  // Fase 4: señalización WebRTC
  callInvite,
  callAccept,
  callReject,
  callEnd,
  sdpOffer,
  sdpAnswer,
  iceCandidate,
}

class MessagePayload {
  final PayloadType type;
  final String from;        // userId del emisor
  final String to;          // userId del receptor
  final String chatId;      // chatId explícito — necesario para FCM offline
  final String ciphertext;  // contenido cifrado (base64)
  final String messageId;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  const MessagePayload({
    required this.type,
    required this.from,
    required this.to,
    this.chatId = '',
    required this.ciphertext,
    required this.messageId,
    required this.timestamp,
    this.metadata,
  });

  String toJson() => jsonEncode({
        'type': type.index,
        'from': from,
        'to': to,
        if (chatId.isNotEmpty) 'chatId': chatId,
        'ciphertext': ciphertext,
        'messageId': messageId,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      });

  factory MessagePayload.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return MessagePayload(
      type: PayloadType.values[(map['type'] as num).toInt()],
      from: map['from'] as String? ?? '',
      to: map['to'] as String? ?? '',
      chatId: map['chatId'] as String? ?? '',
      ciphertext: map['ciphertext'] as String? ?? '',
      messageId: map['messageId'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

class PresencePayload {
  final String userId;
  final bool isOnline;
  final int? lastSeenTimestamp;

  const PresencePayload({
    required this.userId,
    required this.isOnline,
    this.lastSeenTimestamp,
  });

  String toJson() => jsonEncode({
        'type': PayloadType.presenceUpdate.index,
        'userId': userId,
        'isOnline': isOnline,
        if (lastSeenTimestamp != null) 'lastSeen': lastSeenTimestamp,
      });
}

class TypingPayload {
  final String from;
  final String to;
  final String chatId;
  final bool isTyping;

  const TypingPayload({
    required this.from,
    this.to = '',
    required this.chatId,
    required this.isTyping,
  });

  String toJson() => jsonEncode({
        'type': PayloadType.typingIndicator.index,
        'from': from,
        if (to.isNotEmpty) 'to': to,
        'chatId': chatId,
        'isTyping': isTyping,
      });
}

// Payloads de señalización WebRTC (Fase 4)
class CallSignalPayload {
  final PayloadType type;
  final String from;
  final String to;
  final String callId;
  final bool isVideo;
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  const CallSignalPayload({
    required this.type,
    required this.from,
    required this.to,
    required this.callId,
    this.isVideo = false,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  String toJson() => jsonEncode({
        'type': type.index,
        'from': from,
        'to': to,
        'callId': callId,
        'isVideo': isVideo,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (sdpMid != null) 'sdpMid': sdpMid,
        if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
      });

  factory CallSignalPayload.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return CallSignalPayload(
      type: PayloadType.values[map['type'] as int],
      from: map['from'] as String,
      to: map['to'] as String,
      callId: map['callId'] as String,
      isVideo: map['isVideo'] as bool? ?? false,
      sdp: map['sdp'] as String?,
      candidate: map['candidate'] as String?,
      sdpMid: map['sdpMid'] as String?,
      sdpMLineIndex: map['sdpMLineIndex'] as int?,
    );
  }
}
