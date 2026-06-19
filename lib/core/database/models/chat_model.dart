enum ChatType { individual, group, broadcast }

class ChatModel {
  final String id;
  final ChatType type;
  final String name;            // nombre del contacto o del grupo
  final String? avatarPath;
  final String? lastMessageId;
  final String? lastMessagePreview; // descifrado en memoria
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final int? disappearingSeconds; // autodestruir mensajes
  final List<String> memberIds;  // vacio si individual
  final String? description;    // grupos
  final DateTime createdAt;

  const ChatModel({
    required this.id,
    required this.type,
    required this.name,
    this.avatarPath,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.disappearingSeconds,
    this.memberIds = const [],
    this.description,
    required this.createdAt,
  });

  ChatModel copyWith({
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
  }) =>
      ChatModel(
        id: id,
        type: type,
        name: name,
        avatarPath: avatarPath,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted ?? this.isMuted,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        disappearingSeconds: disappearingSeconds,
        memberIds: memberIds,
        description: description,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.index,
        'name': name,
        'avatar_path': avatarPath,
        'last_message_id': lastMessageId,
        'last_message_preview': lastMessagePreview,
        'last_message_at': lastMessageAt?.millisecondsSinceEpoch,
        'unread_count': unreadCount,
        'is_muted': isMuted ? 1 : 0,
        'is_pinned': isPinned ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'disappearing_seconds': disappearingSeconds,
        'member_ids': memberIds.join(','),
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ChatModel.fromMap(Map<String, dynamic> map) => ChatModel(
        id: map['id'] as String,
        type: ChatType.values[map['type'] as int],
        name: map['name'] as String,
        avatarPath: map['avatar_path'] as String?,
        lastMessageId: map['last_message_id'] as String?,
        lastMessagePreview: map['last_message_preview'] as String?,
        lastMessageAt: map['last_message_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_message_at'] as int)
            : null,
        unreadCount: map['unread_count'] as int? ?? 0,
        isMuted: (map['is_muted'] as int?) == 1,
        isPinned: (map['is_pinned'] as int?) == 1,
        isArchived: (map['is_archived'] as int?) == 1,
        disappearingSeconds: map['disappearing_seconds'] as int?,
        memberIds: (map['member_ids'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        description: map['description'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class ContactModel {
  final String id;        // userId en Konecta
  final String displayName;
  final String? phone;
  final String? username;
  final String? avatarPath;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBlocked;
  final String identityPublicKeyHex; // para verificar mensajes
  final DateTime addedAt;

  const ContactModel({
    required this.id,
    required this.displayName,
    this.phone,
    this.username,
    this.avatarPath,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    this.isBlocked = false,
    required this.identityPublicKeyHex,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'phone': phone,
        'username': username,
        'avatar_path': avatarPath,
        'bio': bio,
        'is_online': isOnline ? 1 : 0,
        'last_seen': lastSeen?.millisecondsSinceEpoch,
        'is_blocked': isBlocked ? 1 : 0,
        'identity_public_key': identityPublicKeyHex,
        'added_at': addedAt.millisecondsSinceEpoch,
      };

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        phone: map['phone'] as String?,
        username: map['username'] as String?,
        avatarPath: map['avatar_path'] as String?,
        bio: map['bio'] as String?,
        isOnline: (map['is_online'] as int?) == 1,
        lastSeen: map['last_seen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int)
            : null,
        isBlocked: (map['is_blocked'] as int?) == 1,
        identityPublicKeyHex: map['identity_public_key'] as String,
        addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      );
}
