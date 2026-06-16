// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Actualizado por: dart run tool/bump_version.dart
abstract final class AppVersion {
  static const String version = '1.0.6';
  static const int buildNumber = 8;
  static const String fullVersion = '1.0.6+8';
  static const String displayVersion = 'v1.0.6 (build 8)';

  // Historial de cambios — se actualiza con cada version aprobada
  static const List<VersionEntry> changelog = [
    VersionEntry(
      version: '1.0.6',
      build: 8,
      date: '2026-06-16',
      changes: [
        'Fase 6: Hardening anti-ingenieria inversa',
        'ProGuard/R8 habilitado en builds de release con diccionario de ofuscacion',
        'Minificacion y shrinking de recursos activado (-keep reglas para Flutter/WebRTC/crypto)',
        'Root detection: binarios su, build tags test-keys, paquetes root, Magisk, props peligrosas',
        'Frida detection: puerto 27042, /proc/self/maps, TracerPid, paquetes Xposed',
        'Jailbreak detection en iOS: rutas Cydia/Substrate/SSH',
        'Certificate pinning para el relay con SHA-256 configurable',
        'IntegrityMonitor con severidades: low / high / critical',
        'Verificaciones de seguridad en startup async (no bloquean arranque en dev)',
        'Canal nativo Kotlin (MethodChannel) para detecciones a nivel Android',
        'Debugger detection via Debug.isDebuggerConnected() + FLAG_DEBUGGABLE',
        'Firma criptografica de autoria v1.0.6 incrustada',
      ],
    ),
    VersionEntry(
      version: '1.0.5',
      build: 7,
      date: '2026-06-16',
      changes: [
        'Fase 5: Signal Protocol completo + multimedia',
        'Double Ratchet Algorithm implementado desde cero',
        'X3DH (Extended Triple Diffie-Hellman) para sesiones con PFS',
        'Root Chain Key + Sending/Receiving Chain Keys con auto-ratchet DH',
        'Mensajes fuera de orden manejados (hasta 100 saltados)',
        'Grabacion de notas de voz con deslizamiento para cancelar',
        'Selector de medios: galeria, camara, video, archivos',
        'Grabador de audio con indicador visual animado y contador',
        'Barra de entrada renovada con grabacion de voz integrada',
        'Encriptacion de medios (archivo → AES-256-GCM → almacenamiento local)',
        'Firma criptografica de autoria v1.0.5 incrustada',
      ],
    ),
    VersionEntry(
      version: '1.0.4',
      build: 6,
      date: '2026-06-16',
      changes: [
        'Fase 4: Llamadas de voz y video con WebRTC',
        'Llamadas P2P cifradas extremo a extremo via WebRTC',
        'Videollamadas HD con camara frontal/trasera',
        'Cambio de camara en tiempo real',
        'Altavoz, silenciar, apagar camara',
        'Pantalla de llamada entrante con opciones: aceptar / rechazar / solo voz',
        'Señalización via relay Go: oferta SDP, respuesta, candidatos ICE',
        'Historial de llamadas con duración, estado (perdida/rechazada/contestada)',
        'Botones de llamar desde contactos y desde el historial',
        'Servidor relay Go actualizado para enrutar señalización WebRTC',
      ],
    ),
    VersionEntry(
      version: '1.0.3',
      build: 5,
      date: '2026-06-16',
      changes: [
        'Fase 3: Sistema de mensajeria en tiempo real completo',
        'Burbujas de mensajes con cola, sombra y colores de marca',
        'Soporte para texto, audio, imagen, video y archivos',
        'Preview de respuesta (reply) con deslizamiento',
        'Indicador de escritura animado (tres puntos)',
        'Barra de entrada con emoji, adjuntos, voz y envio',
        'Pantalla de conversacion con carga paginada',
        'Pantalla de nuevo chat (individual y grupo)',
        'Creacion de grupos con hasta 1024 miembros',
        'Cifrado AES-256-GCM de mensajes antes de guardar en SQLite',
        'Cliente WebSocket con reconexion exponencial y ping cada 25s',
        'Servidor relay Go (relay/hub/client) — zero-knowledge del contenido',
        'Lista de chats con datos reales desde SQLite',
        'Menu contextual: responder, copiar, destacar, eliminar, reaccionar',
        'Reacciones rapidas con 6 emojis',
        'Iconos de estado: enviando / enviado / entregado / leido',
        'Firma criptografica de autoria v1.0.3 incrustada',
      ],
    ),
    VersionEntry(
      version: '1.0.1',
      build: 3,
      date: '2026-06-16',
      changes: [
        'Fase 2: Sistema de autenticacion completo',
        'Pantallas de onboarding (3 slides animados)',
        'Registro con numero de telefono o solo nombre de usuario',
        'Verificacion OTP con reenvio y contador',
        'Configuracion de perfil con foto',
        'Generacion de claves Signal Protocol (Ed25519 + X25519) en el dispositivo',
        '100 One-Time PreKeys para Perfect Forward Secrecy',
        'PIN de 6 digitos con PBKDF2-SHA256 (100000 iteraciones)',
        'Desbloqueo biometrico (huella / Face ID)',
        'Pantalla de bloqueo automatico',
        'Almacenamiento seguro en Android Keystore / iOS Keychain',
        'Firma criptografica de autoria v1.0.1 incrustada',
      ],
    ),
    VersionEntry(
      version: '1.0.0',
      build: 1,
      date: '2026-06-16',
      changes: [
        'Lanzamiento inicial de Konecta',
        'Estructura base del proyecto',
        'Sistema de temas dark/light',
        'Firma criptografica de autoria incrustada',
        'Soporte bilingue ES/EN',
        'Navegacion base configurada',
      ],
    ),
  ];
}

class VersionEntry {
  final String version;
  final int build;
  final String date;
  final List<String> changes;

  const VersionEntry({
    required this.version,
    required this.build,
    required this.date,
    required this.changes,
  });
}
