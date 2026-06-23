# Konecta — Instrucciones para Claude

## Regla de Release (OBLIGATORIA — nunca omitir)

Cada vez que se completa una fase, fix importante o feature nueva, el ciclo de release completo es:

### 1. Bump de versión
```powershell
dart run tool/bump_version.dart           # patch (default): 1.2.0 → 1.2.1  ← usar para bug fixes
dart run tool/bump_version.dart minor     # minor: 1.2.0 → 1.3.0             ← usar para features nuevas
dart run tool/bump_version.dart major     # major: 1.2.0 → 2.0.0             ← breaking changes
dart run tool/bump_version.dart build     # solo build number, sin tocar versión (uso interno)
```
**POLÍTICA:** cada release a usuarios debe subir la versión visible. Usar `patch` para fixes,
`minor` para features nuevas, `major` para cambios de arquitectura.

### 2. Firmar el build
```powershell
$env:PATH = "C:\Users\D0nGibaFok\flutter\3.41.7\bin;" + $env:PATH
dart run tool/sign_build.dart
```
Esto actualiza `lib/core/security/build_signature.dart` con la firma Ed25519.

### 3. Actualizar la guía de usuario
- Editar `GUIA_USUARIO.md` — agregar las novedades de la versión al historial
- Mantener la tabla de "Historial de versiones" actualizada

### 4. Compilar el APK release (SIEMPRE release, nunca debug para entregar)
```powershell
$env:PATH = "C:\Users\D0nGibaFok\flutter\3.41.7\bin;" + $env:PATH
Set-Location C:\Konecta
flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
```

### 5. Renombrar el APK con versión
```powershell
$ver = (Select-String "^version:" pubspec.yaml).Line.Split(":")[1].Trim().Split("+")[0]
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "build\konecta-v$ver.apk"
```

### 6. Commit y push del código
```powershell
git add -A
git commit -m "release: Konecta vX.X.X+N — descripción"
git push origin master
```

### 7. Crear GitHub Release y subir el APK
```powershell
$ver = (Select-String "^version:" pubspec.yaml).Line.Split(":")[1].Trim().Split("+")[0]
gh release create "v$ver" "build\konecta-v$ver.apk" `
  --title "Konecta v$ver" `
  --notes "Descripción de los cambios"
```

### 8. Actualizar Firebase Remote Config (OBLIGATORIO — activa el popup en usuarios)
```bash
node tool/update_remote_config.js 1.2.0
```
El script en `tool/update_remote_config.js` renueva el token automáticamente usando el `refresh_token` de Firebase CLI. **Nunca expira** — no requiere `firebase login` antes de cada release.
**Qué actualiza:** `latest_version`, `update_url`, `release_notes_es/en` — el popup aparece automáticamente en todos los usuarios con versión inferior.

---

## Información del proyecto

- **Nombre**: Konecta
- **Autor**: Pedro Espinal
- **Copyright**: Todos los derechos reservados 2026
- **Package**: com.pedroespinal.konecta
- **Repo**: https://github.com/pedroespinal/konecta
- **Firebase**: konecta-app-2026

## Flutter

- **SDK**: 3.41.7 en `C:\Users\D0nGibaFok\flutter\3.41.7\bin`
- **Siempre** prepend al PATH: `$env:PATH = "C:\Users\D0nGibaFok\flutter\3.41.7\bin;" + $env:PATH`

## Seguridad

- La clave privada está en `C:\Konecta\keys\private_key.hex` — **NUNCA subir a git**
- `keys/` está en `.gitignore` — verificar antes de cada push
- `google-services.json` está en `.gitignore` — no subir
- La clave pública: `0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841`

## Footer obligatorio en todas las pantallas

```dart
const KonectaFooter(showVersion: false)
// o
"Creado por: Pedro Espinal  Todos los derechos reservados 2026"
```

## Para publicar nueva versión en Remote Config (sin nueva app)

```bash
node tool/update_remote_config.js <version>
```
El token se renueva automáticamente. Solo hace falta `firebase login` una vez al configurar la máquina por primera vez.
