// Modelos de claves criptograficas de Konecta
// Inspirado en el protocolo Signal (X3DH + Double Ratchet)

class KonectaIdentity {
  final String userId;
  final int registrationId;
  final String identityPublicKeyHex;
  final String signedPreKeyPublicHex;
  final String signedPreKeySignatureHex;
  final int signedPreKeyId;
  final List<KonectaOneTimePreKey> oneTimePreKeys;
  final DateTime createdAt;

  const KonectaIdentity({
    required this.userId,
    required this.registrationId,
    required this.identityPublicKeyHex,
    required this.signedPreKeyPublicHex,
    required this.signedPreKeySignatureHex,
    required this.signedPreKeyId,
    required this.oneTimePreKeys,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'registrationId': registrationId,
        'identityPublicKey': identityPublicKeyHex,
        'signedPreKey': {
          'keyId': signedPreKeyId,
          'publicKey': signedPreKeyPublicHex,
          'signature': signedPreKeySignatureHex,
        },
        'oneTimePreKeys': oneTimePreKeys.map((k) => k.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class KonectaOneTimePreKey {
  final int keyId;
  final String publicKeyHex;

  const KonectaOneTimePreKey({required this.keyId, required this.publicKeyHex});

  Map<String, dynamic> toJson() => {'keyId': keyId, 'publicKey': publicKeyHex};
}

class KonectaUserProfile {
  final String userId;
  final String displayName;
  final String? phone;
  final String? avatarPath;
  final String? bio;
  final DateTime registeredAt;
  final bool hasPin;
  final bool hasBiometrics;

  const KonectaUserProfile({
    required this.userId,
    required this.displayName,
    this.phone,
    this.avatarPath,
    this.bio,
    required this.registeredAt,
    this.hasPin = false,
    this.hasBiometrics = false,
  });

  KonectaUserProfile copyWith({
    String? displayName,
    String? phone,
    String? avatarPath,
    String? bio,
    bool? hasPin,
    bool? hasBiometrics,
  }) =>
      KonectaUserProfile(
        userId: userId,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        avatarPath: avatarPath ?? this.avatarPath,
        bio: bio ?? this.bio,
        registeredAt: registeredAt,
        hasPin: hasPin ?? this.hasPin,
        hasBiometrics: hasBiometrics ?? this.hasBiometrics,
      );
}
