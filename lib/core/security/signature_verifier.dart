import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'build_signature.dart';
import 'integrity_monitor.dart';

abstract final class SignatureVerifier {
  static bool _verified = false;
  static bool _isValid = false;

  // Verifica la firma al arrancar la app. Llama esto desde main() antes
  // de mostrar cualquier pantalla.
  static Future<void> verifyOnStartup() async {
    if (_verified) return;
    _isValid = await _verify();
    _verified = true;

    if (!_isValid) {
      IntegrityMonitor.reportTampering(
        'Firma de build invalida — posible modificacion del binario.',
      );
    }
  }

  // Solo para uso interno / depuracion — nunca exponer en UI
  static bool get isSignatureValid => _isValid;

  static Future<bool> _verify() async {
    try {
      final algorithm = Ed25519();
      final publicKeyBytes = hex.decode(BuildSignature.publicKey);
      final signatureBytes = hex.decode(BuildSignature.signature);
      final payloadBytes = BuildSignature.signedPayload.codeUnits;

      final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
      final signature = Signature(signatureBytes, publicKey: publicKey);

      return await algorithm.verify(payloadBytes, signature: signature);
    } catch (_) {
      return false;
    }
  }
}
