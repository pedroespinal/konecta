enum MessageType { text, image, video, audio, file, location, sticker, system }

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String encryptedContent; // siempre cifrado en DB
  final String? decryptedContent; // solo en memoria, nunca en DB
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToId;      // mensaje al que responde
  final String? mediaPath;      // ruta local del archivo
  final String? mediaMimeType;
  final int? mediaDuration;     // segundos (audio/video)
  final String? reactionEmoji;
  final bool isDeleted;
  final bool isStarred;
  final int? disappearsAt;      // unix timestamp de expiracion

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.encryptedContent,
    this.decryptedContent,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.replyToId,
    this.mediaPath,
    this.mediaMimeType,
    this.mediaDuration,
    this.reactionEmoji,
    this.isDeleted = false,
    this.isStarred = false,
    this.disappearsAt,
  });

  MessageModel copyWith({
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? reactionEmoji,
    bool? isDeleted,
    bool? isStarred,
    String? decryptedContent,
  }) =>
      MessageModel(
        id: id,
        chatId: chatId,
        senderId: senderId,
        type: type,
        encryptedContent: encryptedContent,
        decryptedContent: decryptedContent ?? this.decryptedContent,
        status: status ?? this.status,
        sentAt: sentAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        replyToId: replyToId,
        mediaPath: mediaPath,
        mediaMimeType: mediaMimeType,
        mediaDuration: mediaDuration,
        reactionEmoji: reactionEmoji ?? this.reactionEmoji,
        isDeleted: isDeleted ?? this.isDeleted,
        isStarred: isStarred ?? this.isStarred,
        disappearsAt: disappearsAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'type': type.index,
        'encrypted_content': encryptedContent,
        'status': status.index,
        'sent_at': sentAt.millisecondsSinceEpoch,
        'delivered_at': deliveredAt?.millisecondsSinceEpoch,
        'read_at': readAt?.millisecondsSinceEpoch,
        'reply_to_id': replyToId,
        'media_path': mediaPath,
        'media_mime_type': mediaMimeType,
        'media_duration': mediaDuration,
        'reaction_emoji': reactionEmoji,
        'is_deleted': isDeleted ? 1 : 0,
        'is_starred': isStarred ? 1 : 0,
        'disappears_at': disappearsAt,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String,
        chatId: map['chat_id'] as String,
        senderId: map['sender_id'] as String,
        type: MessageType.values[map['type'] as int],
        encryptedContent: map['encrypted_content'] as String,
        status: MessageStatus.values[map['status'] as int],
        sentAt: DateTime.fromMillisecondsSinceEpoch(map['sent_at'] as int),
        deliveredAt: map['delivered_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['delivered_at'] as int)
            : null,
        readAt: map['read_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['read_at'] as int)
            : null,
        replyToId: map['reply_to_id'] as String?,
        mediaPath: map['media_path'] as String?,
        mediaMimeType: map['media_mime_type'] as String?,
        mediaDuration: map['media_duration'] as int?,
        reactionEmoji: map['reaction_emoji'] as String?,
        isDeleted: (map['is_deleted'] as int?) == 1,
        isStarred: (map['is_starred'] as int?) == 1,
        disappearsAt: map['disappears_at'] as int?,
      );
}
