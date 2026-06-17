# Guía de Usuario — Konecta v1.0.7

**Creado por:** Pedro Espinal  
**Versión:** 1.0.7 (build 9) — 17 de junio de 2026

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
- Ingresa el código de 6 dígitos que se muestra en pantalla
- **Modo demo:** cualquier código de 6 dígitos funciona
- Si el código expira, toca **Reenviar código** después de 60 segundos

---

### 3. Configuración de perfil

1. Escribe tu nombre para mostrar
2. Opcionalmente agrega una foto de perfil y una biografía
3. Toca **Guardar y continuar**

---

### 4. PIN de seguridad (opcional)

El PIN protege el acceso a Konecta si alguien toma tu teléfono.

**Si quieres PIN:**
- Ingresa un PIN de 6 dígitos
- Confírmalo ingresándolo de nuevo
- El PIN se guarda cifrado con PBKDF2-SHA256

**Si NO quieres PIN:**
- Toca el botón **Acceder sin PIN** (visible debajo de la entrada de PIN)
- Puedes configurar un PIN en cualquier momento desde **Ajustes → Seguridad**

---

### 5. Biometría (huella / reconocimiento facial)

Después del PIN, puedes activar el desbloqueo biométrico:

1. Toca **Activar huella digital** (o reconocimiento facial)
2. Escanea tu huella cuando el teléfono lo solicite
3. O toca **Usar solo PIN** / **Omitir** para hacerlo después desde Ajustes

> **Requisito:** El dispositivo debe tener huella o Face ID configurado en los ajustes del sistema Android.

---

## Pantalla principal — Chats

### Pestañas de navegación

| Pestaña | Función |
|---------|---------|
| 💬 **Chats** | Lista de conversaciones |
| 📞 **Llamadas** | Historial y nueva llamada |
| ⭕ **Estados** | Historias de 24 horas |
| 👥 **Contactos** | Lista de contactos |

### Menú de 3 puntos ⋮

Toca el botón **⋮** en la esquina superior derecha de Chats:

| Opción | Función |
|--------|---------|
| Nuevo grupo | Crear conversación grupal |
| Marcar todo como leído | Quita los badges de no leído |
| Chats archivados | Ver chats archivados |
| **Ajustes** | Abre la pantalla de configuración |

---

## Chats

### Iniciar un nuevo chat

1. Toca el botón **+** (ícono de lápiz) en la esquina inferior derecha
2. Busca o selecciona un contacto
3. Escribe tu primer mensaje y envía

### Funciones en el chat

- **Texto:** escribe y envía mensajes de texto cifrados
- **Audio:** mantén presionado el micrófono para grabar notas de voz
- **Archivos:** comparte imágenes, documentos y más
- **Cifrado visual:** el ícono 🔒 confirma que E2E está activo
- **Estados de mensaje:** entregado ✓✓ → leído (marca azul)

---

## Llamadas

- Toca el ícono 📞 en un chat para llamada de voz
- Toca el ícono 📹 para videollamada
- Las llamadas son **P2P (punto a punto)** — no pasan por servidores de Konecta
- Cifradas con DTLS-SRTP

---

## Ajustes

Accede desde el menú **⋮ → Ajustes** en la pantalla principal.

### Apariencia

**Tema de la aplicación:**
- 🌙 **Modo oscuro** — Fondo oscuro elegante, ideal para noche
- ⚙️ **Según el sistema** — Sigue la configuración del teléfono automáticamente
- ☀️ **Modo claro** — Fondo blanco, colores vivos, ideal para exterior

> La preferencia se guarda automáticamente y se restaura al reiniciar la app.

**Idioma:**
- 🇪🇸 **Español** — Interfaz completa en español
- 🇺🇸 **English** — Full interface in English

> El idioma cambia inmediatamente sin necesidad de reiniciar.

### Seguridad

- **Cambiar PIN** — Actualiza tu PIN de 6 dígitos
- **Huella digital** — Activa, desactiva o reconfigura el desbloqueo biométrico

### Cuenta

- **Cerrar sesión** — Cierra la sesión activa. Tus claves y mensajes permanecen en el dispositivo.
- **Eliminar cuenta** — Borra permanentemente tu cuenta, todas tus claves criptográficas y todos los datos locales. **Esta acción es irreversible.**

### Acerca de

- Versión actual de la app
- Información del desarrollador (Pedro Espinal)
- Detalles del protocolo de cifrado

---

## Privacidad y seguridad

### Cifrado extremo a extremo

Konecta implementa el **Signal Protocol** completo:

| Componente | Tecnología |
|-----------|------------|
| Claves de identidad | Ed25519 |
| Intercambio de claves | X25519 + X3DH |
| Renovación por mensaje | Double Ratchet Algorithm |
| Cifrado de mensajes | AES-256-GCM |
| Llamadas | DTLS-SRTP (WebRTC) |
| PIN | PBKDF2-SHA256 (100.000 iteraciones) |
| Almacenamiento de claves | Android Keystore (hardware) |

### Principios de privacidad de Konecta

- Las claves privadas **nunca salen de tu dispositivo**
- Konecta **no puede leer** tus mensajes ni llamadas
- **No se venden ni comparten** tus datos
- **No se requiere** número de teléfono (opción de solo usuario)
- El servidor relay solo transmite datos cifrados — no puede descifrarlos

---

## Actualizaciones automáticas

Cuando haya una versión nueva disponible en GitHub, verás un aviso al abrir Konecta:

- Toca **"Actualizar"** para ir a la página de descarga en GitHub Releases
- Toca **"Ahora no"** para cerrar el aviso y actualizar más tarde
- Si la actualización es **obligatoria** (cambio de seguridad crítico), el aviso no se puede cerrar

---

## Preguntas frecuentes

**¿Por qué no me llega el SMS?**  
En la versión actual (demo), el envío de SMS real no está activo. Ingresa cualquier código de 6 dígitos.

**¿Qué pasa si olvido el PIN?**  
Actualmente debes reinstalar la app. Una versión futura incluirá recuperación con copia de seguridad cifrada.

**¿El acceso sin PIN es seguro?**  
Sin PIN de Konecta, el bloqueo depende del sistema Android (huella, patrón, PIN del sistema). Si el teléfono tiene bloqueo de pantalla, estás protegido.

**¿Puedo usar Konecta sin número de teléfono?**  
Sí. Elige "Solo usuario" en el registro para mayor anonimato.

**¿Dónde se guardan mis claves criptográficas?**  
En el Android Keystore, respaldado por hardware en dispositivos compatibles. Son inaccesibles sin tu PIN o biometría.

**¿Puedo cambiar el idioma?**  
Sí, desde **Ajustes → Apariencia → Idioma**. El cambio es inmediato.

**¿Cómo activo el modo oscuro?**  
Desde **Ajustes → Apariencia → Tema**. Elige Oscuro, Claro, o Según el sistema.

---

## Historial de versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| **1.0.7** | jun 2026 | Biometría corregida; menú ⋮ funcional; pantalla Ajustes completa (tema/idioma/seguridad/cuenta); OTP modo demo; botón Acceder sin PIN; permisos AndroidManifest |
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

Konecta is a secure, private messaging app with end-to-end (E2E) encryption. Your messages, calls, and files are encrypted in transit — nobody, not even Konecta, can read them.

### Registration

**Option A — Phone number:** Enter your country code and phone number, accept terms, tap Continue. Enter any 6-digit code (demo mode).

**Option B — Username only:** Greater privacy — no phone number required. Use only letters, numbers, dots, and underscores.

### PIN Setup (optional)

The PIN locks Konecta on your device. If you don't want a PIN, tap **Access without PIN** — you can always set one later from Settings.

### Settings

Access via the **⋮ menu → Settings** on the main screen.

- **Theme:** Dark / System default / Light — persisted across restarts
- **Language:** Español / English — changes instantly
- **Change PIN:** Update your 6-digit unlock PIN
- **Biometric:** Configure fingerprint or face recognition
- **Sign out:** Close session without deleting your keys
- **Delete account:** Permanently erase your account, keys, and all local data

### Privacy

Konecta uses the full Signal Protocol (Ed25519, X25519, X3DH, Double Ratchet, AES-256-GCM). Private keys never leave your device. No data is sold or shared. No phone number required.

---

*© 2026 Pedro Espinal. All rights reserved.*  
*Konecta — Secure and private messaging*
