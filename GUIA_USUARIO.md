# Konecta — Guía de Usuario
**Versión 1.0.6 | Build 8 | 2026-06-16**
*Creado por: Pedro Espinal — Todos los derechos reservados 2026*

---

## ¿Qué es Konecta?

Konecta es una aplicación de mensajería segura y privada que combina lo mejor de WhatsApp, Signal y Telegram. Todos los mensajes, llamadas y archivos están cifrados de extremo a extremo — ni siquiera los servidores pueden leer tu contenido.

---

## Instalación

### Android
1. Descarga el archivo `konecta-v1.0.6.apk` desde [GitHub Releases](https://github.com/pedroespinal/konecta/releases/latest)
2. En tu teléfono: **Ajustes → Seguridad → Instalar apps de fuentes desconocidas** → Activar
3. Abre el archivo APK y toca **Instalar**
4. Abre Konecta y sigue el proceso de registro

---

## Primeros pasos

### 1. Registro
- Ingresa tu número de teléfono **o** solo un nombre de usuario
- Si usas teléfono: recibirás un código OTP de 6 dígitos
- Configura tu foto y nombre de perfil

### 2. PIN de seguridad
- Crea un PIN de 6 dígitos
- Este PIN protege todos tus mensajes locales
- Puedes activar también **desbloqueo biométrico** (huella / Face ID)

### 3. Tus claves criptográficas
Al registrarte, Konecta genera automáticamente en tu dispositivo:
- **Clave de identidad Ed25519** — identifica tu cuenta de forma única
- **100 PreKeys X25519** — garantizan Perfect Forward Secrecy
- Las claves **nunca salen de tu dispositivo**

---

## Mensajería

### Enviar mensajes
- Toca el ícono ✏️ para iniciar un nuevo chat
- Escribe y toca el botón de envío, o desliza para grabar una nota de voz

### Tipos de mensajes soportados
| Tipo | Descripción |
|------|-------------|
| Texto | Mensajes de texto ilimitados |
| Nota de voz | Mantén presionado el micrófono, suelta para enviar |
| Foto | Desde cámara o galería |
| Video | Desde cámara o galería |
| Archivo | Cualquier tipo de archivo |

### Responder a un mensaje
- Desliza el mensaje hacia la derecha para responder
- Aparece una vista previa del mensaje original

### Reaccionar a un mensaje
- Mantén presionado un mensaje
- Elige una de las 6 reacciones rápidas: 👍 ❤️ 😂 😮 😢 🙏

### Indicadores de estado
| Ícono | Significado |
|-------|-------------|
| 🕐 | Enviando |
| ✓ | Enviado al servidor |
| ✓✓ | Entregado al destinatario |
| ✓✓ (cyan) | Leído por el destinatario |

---

## Grupos

- Toca ✏️ → pestaña **"Nuevo grupo"**
- Selecciona los miembros (hasta 1,024 personas)
- Escribe el nombre del grupo y crea

---

## Llamadas

### Llamada de voz
- Abre un chat → toca el ícono 📞
- O desde la pestaña **Llamadas** → toca ➕

### Videollamada
- Abre un chat → toca el ícono 🎥
- O desde **Llamadas** → toca el ícono de cámara junto al contacto

### Durante la llamada
| Botón | Acción |
|-------|--------|
| 🎤 | Silenciar / activar micrófono |
| 📷 | Apagar / encender cámara |
| 🔄 | Cambiar cámara (frontal ↔ trasera) |
| 🔊 | Altavoz / auricular |
| 🔴 | Colgar |

### Llamada entrante
Al recibir una llamada verás tres opciones:
- **Rechazar** (rojo) — declina la llamada
- **Solo voz** — acepta sin video aunque sea videollamada
- **Aceptar** (verde) — acepta con video

---

## Seguridad y privacidad

### Cifrado de extremo a extremo
- **X3DH** (Extended Triple Diffie-Hellman) para establecer sesiones seguras
- **Double Ratchet Algorithm** — cada mensaje usa una clave diferente
- **AES-256-GCM** — cifrado militar para todos los mensajes y archivos
- Perfect Forward Secrecy — si una clave se compromete, los mensajes anteriores siguen seguros

### Protecciones del dispositivo
Konecta detecta automáticamente entornos inseguros:
- **Root / Jailbreak** — dispositivos rooteados son identificados
- **Frida / Xposed** — herramientas de hooking son detectadas
- **MITM** — certificate pinning protege la conexión al servidor

### Bloqueo automático
- La app se bloquea automáticamente cuando va al fondo
- Requiere PIN o biometría para desbloquear

---

## Notas de voz

1. Mantén presionado el micrófono 🎤 en la barra de entrada
2. Habla — verás el indicador de grabación con el tiempo transcurrido
3. **Suelta** para enviar automáticamente
4. **Desliza a la izquierda** para cancelar sin enviar

---

## Configuración

### Tema
- Konecta soporta **modo oscuro** y **modo claro**
- Sigue la configuración del sistema automáticamente

### Idioma
- **Español** (predeterminado)
- **English** — disponible en configuración

---

## Solución de problemas

| Problema | Solución |
|----------|---------|
| No recibo mensajes | Verifica tu conexión a internet; el relay reconecta automáticamente |
| La llamada se corta | WebRTC intenta conexión P2P; en redes restrictivas usa el relay |
| Olvidé mi PIN | Por seguridad no hay recuperación — desinstala y vuelve a registrarte |
| La app me pide actualizar | Hay una nueva versión disponible; toca "Actualizar" para descargar |

---

## Actualizaciones

Konecta verifica automáticamente si hay una nueva versión al abrir la app. Cuando hay una actualización disponible, verás un popup con:
- La versión actual y la nueva versión
- Las novedades del release
- Botón **"Actualizar"** → abre el link de descarga
- Botón **"Ahora no"** → posponer (solo en actualizaciones opcionales)

---

## Historial de versiones

| Versión | Novedades principales |
|---------|----------------------|
| **1.0.6** | Hardening: root detection, Frida detection, cert pinning, ProGuard/R8 |
| **1.0.5** | Double Ratchet + X3DH completos, notas de voz, multimedia |
| **1.0.4** | Llamadas de voz y video WebRTC |
| **1.0.3** | Mensajería en tiempo real, grupos, reacciones, estado de mensajes |
| **1.0.1** | Autenticación completa, PIN, biometría, Signal Protocol |
| **1.0.0** | Lanzamiento inicial |

---

*Creado por: Pedro Espinal — Todos los derechos reservados 2026*
