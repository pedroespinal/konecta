#!/usr/bin/env node
// Actualiza Firebase Remote Config — se llama desde el ciclo de release.
// Usa refresh_token para obtener un access_token fresco automáticamente.
// Nunca expira mientras Firebase CLI esté configurado en esta máquina.

const path = require('path'), os = require('os'), fs = require('fs'), https = require('https');

const PROJECT_ID = 'konecta-app-2026';

// Credenciales públicas del Firebase CLI (open source)
const CLIENT_ID     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function post(hostname, path, body, headers) {
  return new Promise((resolve, reject) => {
    const data = typeof body === 'string' ? body : JSON.stringify(body);
    const req = https.request(
      { hostname, path, method: 'POST', headers: { ...headers, 'Content-Length': Buffer.byteLength(data) } },
      res => { let b = ''; res.on('data', d => b += d); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: b })); }
    );
    req.on('error', reject);
    req.end(data);
  });
}

function get(hostname, path, headers) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      { hostname, path, method: 'GET', headers },
      res => { let b = ''; res.on('data', d => b += d); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: b })); }
    );
    req.on('error', reject);
    req.end();
  });
}

function put(hostname, path, body, headers) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request(
      { hostname, path, method: 'PUT', headers: { ...headers, 'Content-Length': Buffer.byteLength(data) } },
      res => { let b = ''; res.on('data', d => b += d); res.on('end', () => resolve({ status: res.statusCode, body: b })); }
    );
    req.on('error', reject);
    req.end(data);
  });
}

async function getAccessToken() {
  const cfg = JSON.parse(fs.readFileSync(
    path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'), 'utf8'
  ));

  // Si el access_token aún es válido (con 60s de margen), reutilizarlo
  const expiresAt = cfg.tokens?.expires_at;
  if (expiresAt && Date.now() < expiresAt - 60000) {
    return cfg.tokens.access_token;
  }

  // Renovar con el refresh_token
  const refreshToken = cfg.tokens?.refresh_token;
  if (!refreshToken) throw new Error('No hay refresh_token en firebase-tools.json. Ejecuta: firebase login');

  const body = `client_id=${encodeURIComponent(CLIENT_ID)}&client_secret=${encodeURIComponent(CLIENT_SECRET)}&refresh_token=${encodeURIComponent(refreshToken)}&grant_type=refresh_token`;
  const res = await post('oauth2.googleapis.com', '/token', body, { 'Content-Type': 'application/x-www-form-urlencoded' });
  const json = JSON.parse(res.body);
  if (!json.access_token) throw new Error('Error al renovar token: ' + res.body);

  // Guardar el nuevo access_token en firebase-tools.json
  cfg.tokens.access_token = json.access_token;
  cfg.tokens.expires_in   = json.expires_in;
  cfg.tokens.expires_at   = Date.now() + (json.expires_in - 60) * 1000;
  fs.writeFileSync(
    path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'),
    JSON.stringify(cfg, null, 2)
  );
  console.log('  Token renovado OK');
  return json.access_token;
}

async function main() {
  const ver = process.argv[2];
  if (!ver) { console.error('Uso: node update_remote_config.js <version>  (ej: 1.2.1)'); process.exit(1); }

  console.log(`Actualizando Remote Config → v${ver} ...`);
  const token = await getAccessToken();

  const base = `/v1/projects/${PROJECT_ID}/remoteConfig`;

  // GET para obtener ETag
  const getRes = await get('firebaseremoteconfig.googleapis.com', base,
    { Authorization: 'Bearer ' + token, 'Accept-Encoding': 'identity' });
  const etag = getRes.headers['etag'] || '*';

  const params = {
    parameters: {
      latest_version:       { defaultValue: { value: ver }, description: 'Version mas reciente de Konecta', valueType: 'STRING' },
      update_check_enabled: { defaultValue: { value: 'true' }, description: 'Habilitar verificacion de actualizaciones', valueType: 'BOOLEAN' },
      min_required_version: { defaultValue: { value: '1.0.0' }, description: 'Version minima soportada', valueType: 'STRING' },
      update_url:           { defaultValue: { value: `https://github.com/pedroespinal/konecta/releases/tag/v${ver}` }, description: 'URL de descarga', valueType: 'STRING' },
      release_notes_es:     { defaultValue: { value: `v${ver}: Mensajes funcionando, emojis, compartir QR, directorio telefonico` }, description: 'Notas en Espanol', valueType: 'STRING' },
      release_notes_en:     { defaultValue: { value: `v${ver}: Messages working, emoji picker, QR sharing, phone contacts directory` }, description: 'Release notes in English', valueType: 'STRING' },
    }
  };

  const putRes = await put('firebaseremoteconfig.googleapis.com', base, params, {
    Authorization: 'Bearer ' + token,
    'Content-Type': 'application/json; charset=UTF-8',
    'If-Match': etag,
  });

  if (putRes.status === 200) {
    console.log(`✅ Remote Config actualizado: latest_version = ${ver}`);
  } else {
    console.error(`❌ Error ${putRes.status}: ${putRes.body}`);
    process.exit(1);
  }
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
