# Konecta

Mensajería segura y privada — cifrado E2E, relay propio, cero metadatos.

**Autor:** Pedro Espinal  
**Versión:** 1.2.0+14  
**Package:** com.pedroespinal.konecta  
**Firebase:** konecta-app-2026

---

## Stack

- **Flutter 3.41.7** — Android (release)
- **Signal Protocol** — Ed25519, X25519, X3DH, Double Ratchet, AES-256-GCM
- **Relay Go** — WebSocket zero-knowledge en Railway (`relay-production-38eb.up.railway.app`)
- **Firebase** — Remote Config (actualizaciones) + FCM (push offline)
- **SQLite** — historial local cifrado

## Release

```powershell
# 1. Bump version
dart run tool/bump_version.dart
# 2. Firmar
$env:PATH = "C:\Users\D0nGibaFok\flutter\3.41.7\bin;" + $env:PATH
dart run tool/sign_build.dart
# 3. Compilar APK release
flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
```

Ver `CLAUDE.md` para el ciclo de release completo (pasos 1–8).

## Seguridad

- Clave privada en `keys/private_key.hex` — NUNCA en git
- `keys/` y `google-services.json` en `.gitignore`
- Clave pública: `0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841`

---

© 2026 Pedro Espinal. Todos los derechos reservados.
