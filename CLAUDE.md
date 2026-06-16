# Konecta — Instrucciones para Claude

## Regla de Release (OBLIGATORIA — nunca omitir)

Cada vez que se completa una fase, fix importante o feature nueva, el ciclo de release completo es:

### 1. Bump de versión
```powershell
dart run tool/bump_version.dart   # sube el build number automáticamente
```
O editar manualmente `pubspec.yaml` y `lib/core/constants/app_version.dart`.

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

1. Ir a https://console.firebase.google.com/project/konecta-app-2026/remoteconfig
2. Cambiar `latest_version` al nuevo número
3. Publicar → el popup aparece automáticamente en todos los usuarios
