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

### 8. Actualizar Firebase Remote Config (OBLIGATORIO — activa el popup en usuarios)
```powershell
# Genera rc_release.json con los nuevos valores y llama la REST API
$ver = (Select-String "^version:" pubspec.yaml).Line.Split(":")[1].Trim().Split("+")[0]
node -e @"
const path = require('path'), os = require('os'), fs = require('fs'), https = require('https');
const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'), 'utf8'));
const token = cfg.tokens.access_token;
const projectId = 'konecta-app-2026';
const ver = '$ver';
const body = JSON.stringify({ parameters: {
  latest_version:      { defaultValue: { value: ver }, description: 'Version mas reciente de Konecta', valueType: 'STRING' },
  update_check_enabled:{ defaultValue: { value: 'true' }, description: 'Habilitar verificacion de actualizaciones', valueType: 'BOOLEAN' },
  min_required_version:{ defaultValue: { value: '1.0.0' }, description: 'Version minima soportada', valueType: 'STRING' },
  update_url:          { defaultValue: { value: 'https://github.com/pedroespinal/konecta/releases/tag/v' + ver }, description: 'URL de descarga', valueType: 'STRING' },
  release_notes_es:    { defaultValue: { value: 'v' + ver + ': descripcion en espanol' }, description: 'Notas en Espanol', valueType: 'STRING' },
  release_notes_en:    { defaultValue: { value: 'v' + ver + ': description in English' }, description: 'Release notes in English', valueType: 'STRING' }
}});
const base = '/v1/projects/' + projectId + '/remoteConfig';
https.request({ hostname:'firebaseremoteconfig.googleapis.com', path: base, method:'GET', headers:{ Authorization:'Bearer '+token,'Accept-Encoding':'gzip' }}, r => {
  const etag = r.headers['etag']; let b=''; r.on('data',d=>b+=d);
  r.on('end', () => {
    https.request({ hostname:'firebaseremoteconfig.googleapis.com', path: base, method:'PUT', headers:{ Authorization:'Bearer '+token,'Content-Type':'application/json; charset=UTF-8','If-Match':etag }}, r2 => {
      let b2=''; r2.on('data',d=>b2+=d); r2.on('end',()=>console.log('RC actualizado:', r2.statusCode===200?'OK':b2));
    }).end(body);
  });
}).end();
"@
```
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

Usar el paso 8 del ciclo de release de arriba (Node.js + REST API).
El token del Firebase CLI se lee automáticamente de `~/.config/configstore/firebase-tools.json`.
Si el token expiró, ejecutar `firebase login` primero.
