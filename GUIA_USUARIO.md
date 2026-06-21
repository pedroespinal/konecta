# Guía de Usuario — Konecta v1.2.0

**Creado por:** Pedro Espinal  
**Versión:** 1.2.0 (build 14) — 19 de junio de 2026

---

## ¿Qué es Konecta?

Konecta es una aplicación de mensajería segura y privada con cifrado de extremo a extremo (E2E). Tus mensajes, llamadas y archivos viajan cifrados — nadie, ni siquiera Konecta, puede leerlos.

---

## Primeros pasos

### 1. Registro

Al abrir Konecta por primera vez, verás la pantalla de registro.

**Opción A — Número de teléfono:**
1. Selecciona tu país con el selector de bandera
2. Escribe tu número de teléfono
3. Acepta los Términos de servicio y Política de privacidad
4. Toca **Continuar**
5. Ingresa el código de verificación de 6 dígitos (ver nota demo)

**Opción B — Solo usuario (mayor privacidad):**
1. Elige la pestaña "Solo usuario"
2. Escribe un nombre de usuario (mínimo 3 caracteres, solo letras, números, puntos y guiones bajos)
3. Acepta los términos y toca **Continuar**
4. No se requiere número de teléfono

> **Nota demo:** En esta versión, el envío de SMS real aún no está activo. Puedes usar **cualquier código de 6 dígitos** para avanzar.

---

### 2. Verificación OTP

Si elegiste registro con número de teléfono:
- Ingresa el código de 6 dígitos
- **Modo demo:** cualquier código de 6 dígitos funciona
- Si el código expira, toca **Reenviar código** después de 60 segundos

---

### 3. Configuración de perfil

1. Toca el círculo de avatar para agregar una foto de perfil (galería o cámara)
2. Escribe tu nombre para mostrar
3. Opcionalmente agrega una biografía
4. Toca **Crear cuenta y generar claves**

---

### 4. PIN de seguridad (opcional)

El PIN protege el acceso a Konecta si alguien toma tu teléfono.

**Si quieres PIN:**
- Ingresa un PIN de 6 dígitos
- Confírmalo ingresándolo de nuevo
- El PIN se guarda cifrado con PBKDF2-SHA256

**Si NO quieres PIN:**
- Toca el botón **Acceder sin PIN** (siempre visible, no se oculta bajo el teclado)
- Puedes configurar un PIN en cualquier momento desde **Ajustes → Seguridad**

> **v1.0.8:** El botón Atrás durante la configuración de PIN ya no te saca del flujo de registro.

---

### 5. Biometría (huella / reconocimiento facial)

Después del PIN, puedes activar el desbloqueo biométrico:

1. Toca **Activar huella digital**
2. Escanea tu huella cuando el teléfono lo solicite
3. O toca **Usar solo PIN** / **Omitir** para hacerlo después desde Ajustes

> **v1.0.8:** La biometría ahora funciona correctamente en todos los dispositivos Android.

---

## Pantalla principal — Chats

### Pestañas de navegación

| Pestaña | Función |
|---------|---------|
| 💬 **Chats** | Lista de conversaciones |
| 📞 **Llamadas** | Historial y nueva llamada |
| ⭕ **Estados** | Historias de 24 horas |
| 👥 **Contactos** | Lista de contactos |

### Botones de la barra superior

| Botón | Función |
|-------|---------|
| 📷 QR | Abre tu código QR personal |
| 🔍 Buscar | Busca chats por nombre o mensaje |
| ⋮ Menú | Nuevo grupo, marcar leído, archivados, Ajustes |

---

## Código QR — Agregar contactos

Toca el ícono QR en la barra superior de Chats (o en **Ajustes → Perfil → QR**):

- **Ver tu QR:** muestra tu código único para que otros te agreguen
- **Copiar ID:** toca el ID para copiarlo al portapapeles
- **Compartir:** comparte tu QR por otros medios
- **Escanear QR:** toca el botón "Escanear código de un contacto" para abrir la cámara

El QR está vinculado a tus claves Ed25519 y solo sirve para agregar contactos.

---

## Búsqueda de chats

Toca el ícono 🔍 en la barra superior:

- Filtra chats en tiempo real por nombre o último mensaje
- Los resultados resaltan en color teal las coincidencias
- Toca cualquier resultado para abrir el chat

---

## Ajustes

Accede desde el menú **⋮ → Ajustes** en la pantalla principal.

### Perfil

- **Foto de perfil:** toca el avatar para cambiarla (galería o cámara)
- **Nombre y teléfono:** se muestran en el perfil
- **ID:** toca para copiar tu ID único
- **QR:** acceso directo a tu código QR

### Apariencia

**Tema de la aplicación:**
- 🌙 **Modo oscuro** — Teal Esmeralda sobre fondo casi negro (texto WCAG AA/AAA)
- ⚙️ **Según el sistema** — Sigue la configuración del teléfono
- ☀️ **Modo claro** — Teal sobre fondo azul muy claro

**Idioma:**
- 🇪🇸 **Español**
- 🇺🇸 **English**

### Seguridad

- **Cambiar PIN** — Actualiza tu PIN de 6 dígitos
- **Huella digital** — Configura el desbloqueo biométrico
- **Mi código QR** — Comparte para agregar contactos

### Privacidad

- **Bloqueo de captura de pantalla** — Impide capturas y grabación de pantalla (activado por defecto)
- **Bloqueo automático** — Bloquea Konecta automáticamente: inmediatamente / 1 min / 5 min / 15 min / 1 hora / nunca

### Cuenta

- **Cerrar sesión** — Cierra la sesión activa (mantiene claves y mensajes)
- **Eliminar cuenta** — Borra permanentemente cuenta, claves y todos los datos

### Acerca de

- Versión actual de la app
- Desarrollador: Pedro Espinal
- Cifrado: Signal Protocol — E2E — AES-256-GCM
- Próximas funciones en v1.1.0

---

## Chats

### Iniciar un nuevo chat

1. Toca el botón **+** en la esquina inferior derecha
2. Selecciona un contacto
3. Escribe tu primer mensaje y envía

### Funciones en el chat

- **Texto:** mensajes cifrados extremo a extremo
- **Audio:** mantén presionado el micrófono para grabar
- **Archivos:** imágenes, documentos y más
- **Cifrado visual:** el ícono 🔒 confirma E2E activo
- **Estados de mensaje:** enviado ✓ → entregado ✓✓ → leído (azul)

---

## Llamadas

- Llamadas de voz y video **P2P (punto a punto)**
- No pasan por servidores de Konecta
- Cifradas con DTLS-SRTP

---

## Privacidad y seguridad

### Cifrado extremo a extremo

| Componente | Tecnología |
|-----------|------------|
| Claves de identidad | Ed25519 |
| Intercambio de claves | X25519 + X3DH |
| Renovación por mensaje | Double Ratchet Algorithm |
| Cifrado de mensajes | AES-256-GCM |
| Llamadas | DTLS-SRTP (WebRTC) |
| PIN | PBKDF2-SHA256 (100.000 iteraciones) |
| Almacenamiento de claves | Android Keystore (hardware) |
| Capturas de pantalla | FLAG_SECURE (bloqueadas por defecto) |

### Principios de privacidad

- Las claves privadas **nunca salen de tu dispositivo**
- Konecta **no puede leer** tus mensajes ni llamadas
- **No se venden ni comparten** tus datos
- **No se requiere** número de teléfono
- El servidor relay solo transmite datos cifrados

---

## Actualizaciones automáticas

Cuando haya una versión nueva disponible en GitHub:

- Toca **"Actualizar"** para ir a la página de descarga
- Toca **"Ahora no"** para actualizar más tarde
- Si es obligatoria (cambio de seguridad crítico), el aviso no se puede cerrar

---

## Novedades en v1.2.0

| Función | Descripción |
|---------|-------------|
| 🟣 Violeta Konecta | Nueva identidad visual — color firma exclusivo de Konecta |
| 🚨 PIN de pánico | PIN alternativo que muestra app vacía — nadie sabrá que hay datos reales |
| ☁️ Relay en producción | WebSocket relay Go desplegado en Railway — mensajes en tiempo real activos |
| 🔔 Push FCM offline | FCM configurado con Firebase Admin SDK — notificaciones cuando el destinatario está offline |
| 🔗 WebSocket activo | HomeScreen conecta automáticamente al iniciar; reconexión automática con backoff |

### PIN de pánico — cómo usarlo

1. Ve a **Ajustes → Seguridad → PIN de pánico**
2. Configura un PIN diferente al tuyo real
3. Si alguien te pide el PIN de desbloqueo, ingresa el PIN de pánico
4. Konecta se abre mostrando una app completamente vacía — sin chats, sin contactos
5. Nadie sabrá que existen datos reales

## Próximas funciones — v1.3.0

| Función | Descripción |
|---------|-------------|
| 🎨 Stickers | Packs de stickers animados |
| 🖼️ Fondos de chat | Personaliza el fondo de cada conversación |
| 📌 Fijar mensajes | Fija mensajes importantes en el chat |
| 📅 Mensajes programados | Programa mensajes para más tarde |
| 📍 Ubicación | Comparte tu ubicación en tiempo real |
| 📊 Encuestas | Crea encuestas en grupos |

---

## Preguntas frecuentes

**¿Por qué no me llega el SMS?**  
En la versión actual (demo), el envío de SMS real no está activo. Ingresa cualquier código de 6 dígitos.

**¿Qué pasa si olvido el PIN?**  
Actualmente debes reinstalar la app. Una versión futura incluirá recuperación con copia de seguridad cifrada.

**¿Por qué no puedo tomar capturas de pantalla?**  
Konecta bloquea las capturas por seguridad. Puedes desactivarlo en **Ajustes → Privacidad → Bloqueo de captura**.

**¿Cómo agrego un contacto?**  
Comparte tu código QR (ícono QR en Chats o en Ajustes → Mi código QR) o tu ID de usuario.

**¿El acceso sin PIN es seguro?**  
Sin PIN de Konecta, el bloqueo depende del sistema Android. Si el teléfono tiene bloqueo de pantalla, estás protegido.

**¿Puedo usar Konecta sin número de teléfono?**  
Sí. Elige "Solo usuario" en el registro para mayor anonimato.

**¿Dónde se guardan mis claves criptográficas?**  
En el Android Keystore, respaldado por hardware. Son inaccesibles sin tu PIN o biometría.

---

## Historial de versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| **1.2.0+16** | jun 2026 | **Versión visible**: chip de versión en el app bar de Chats + footer activado; **Guía de usuario** integrada en la app (menú ⋮ → Guía de usuario, también en Ajustes → Acerca de) con 6 secciones: Mensajes, Contactos, Llamadas, Seguridad, Ajustes y Acerca de |
| **1.2.0+15** | jun 2026 | **Mensajes funcionando**: corrección de enrutamiento WebSocket y clave de cifrado simétrica compartida; **selector de emojis** en el chat; **compartir QR** con share sheet nativo; **directorio telefónico** en pestaña Contactos con botón Invitar; chats archivados en bottom sheet; lista de chats vacía sin datos de demostración |
| **1.2.0+14** | jun 2026 | **Relay en producción** (Railway); WebSocket activo desde HomeScreen; FCM push offline con Firebase Admin SDK; URL real del relay configurada |
| **1.2.0+13** | jun 2026 | **Violeta Konecta** (nueva identidad); **PIN de pánico** (modo decoy); backend Railway listo; FCM push notifications |
| 1.1.0 | jun 2026 | **Capa 1 completa**: Escáner QR funcional; mensajes efímeros configurables; editar mensajes; destacar y ver mensajes guardados; estados de texto reales; responder y reaccionar ya operativos; menú contextual mejorado |
| 1.0.9 | jun 2026 | **Bug fixes de navegación**: botón Actualizar ahora abre GitHub; tap en Estado, Invitar amigos, Agregar amigos y Crear grupos ya funcionan; manifest Android con queries HTTPS para url_launcher |
| 1.0.8 | jun 2026 | **Teal Esmeralda** (paleta nueva, dark mode legible); biometría CORREGIDA; lock screen navega al home; PIN back button corregido; QR personal; búsqueda de chats; bloqueo capturas; auto-lock; foto de perfil en Ajustes |
| 1.0.7 | jun 2026 | Permisos biometría; OTP demo; PIN spinner; menú ⋮ funcional; pantalla Ajustes; persistencia tema/idioma; Acceder sin PIN |
| 1.0.6 | jun 2026 | APK release firmado con RSA-4096; Firebase Remote Config; popup de actualización |
| 1.0.5 | jun 2026 | Llamadas WebRTC P2P; notas de voz; reproducción de audio |
| 1.0.4 | jun 2026 | Base de datos SQLite; historial de mensajes; burbujas de chat |
| 1.0.3 | jun 2026 | Signal Protocol completo (X3DH + Double Ratchet); relay WebSocket |
| 1.0.2 | jun 2026 | Autenticación; PIN; biometría; pantalla de bloqueo |
| 1.0.1 | jun 2026 | Pantallas base; navegación; temas; internacionalización |
| 1.0.0 | jun 2026 | Versión inicial |

---

## User Guide (English)

### What is Konecta?

Konecta is a secure, private messaging app with end-to-end (E2E) encryption. Nobody, not even Konecta, can read your messages.

### Registration

**Option A — Phone number:** Enter country code and phone number, accept terms, tap Continue. Enter any 6-digit code (demo mode).

**Option B — Username only:** Greater privacy — no phone number required.

### Profile Setup

Tap the avatar circle to add a profile photo from gallery or camera. Enter display name, optional bio, tap **Create account**.

### PIN Setup (optional)

The **Access without PIN** button is always visible and never hidden by the keyboard. The Back button no longer exits the registration flow.

### Biometrics

Fixed in v1.0.8 — works correctly on all Android devices.

### QR Code

Tap the QR icon in the Chats bar. Shows your personal QR code for others to scan and add you. Tap your User ID to copy it.

### Chat Search

Tap 🔍 in the Chats bar. Real-time filtering by name or message, with highlighted matches.

### Settings

- **Profile:** Edit avatar, copy User ID, access QR
- **Theme:** Dark (Teal Esmeralda) / System / Light
- **Language:** Español / English
- **Screen security:** Block screenshots (on by default) — toggle in Privacy
- **Auto-lock:** Immediately / 1min / 5min / 15min / 1h / never
- **Sign out / Delete account**

### New in v1.2.0

Violet Konecta brand color · Panic PIN (decoy mode — shows empty app) · Railway backend ready · FCM push notifications

### Coming in v1.3.0

Sticker packs · Chat wallpapers · Pinned messages · Scheduled messages · Location sharing · Polls in groups

### Privacy

Signal Protocol (Ed25519, X25519, X3DH, Double Ratchet, AES-256-GCM). Private keys never leave your device. Screenshots blocked by FLAG_SECURE. No data sold or shared. No phone number required.

---

*© 2026 Pedro Espinal. All rights reserved.*  
*Konecta — Secure and private messaging*
