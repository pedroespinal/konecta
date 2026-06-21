import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_version.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/konecta_footer.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final Set<int> _expanded = {0};

  static const _sections = [
    _GuideSection(
      icon: Icons.chat_bubble_rounded,
      color: KonectaColors.primary,
      title: 'Mensajes',
      items: [
        _GuideItem(
          icon: Icons.send_rounded,
          title: 'Enviar un mensaje',
          body: 'Toca el chat de un contacto, escribe en la barra inferior y presiona el botón de envío (▶). Todos los mensajes van cifrados con AES-256-GCM antes de salir de tu dispositivo.',
        ),
        _GuideItem(
          icon: Icons.emoji_emotions_rounded,
          title: 'Emojis',
          body: 'Toca el ícono de carita 😊 en la barra de escritura para abrir el selector de emojis. Puedes buscar emojis por nombre. Toca el ícono de teclado para volver a escribir.',
        ),
        _GuideItem(
          icon: Icons.attach_file_rounded,
          title: 'Adjuntos y archivos',
          body: 'Toca el ícono de clip 📎 dentro del campo de texto para enviar fotos de galería, tomar una foto o adjuntar un archivo. Los archivos también van cifrados.',
        ),
        _GuideItem(
          icon: Icons.mic_rounded,
          title: 'Notas de voz',
          body: 'Mantén presionado el ícono de micrófono 🎙️ para grabar una nota de voz. Desliza hacia la izquierda mientras grabas para cancelar sin enviar.',
        ),
        _GuideItem(
          icon: Icons.reply_rounded,
          title: 'Responder un mensaje',
          body: 'Mantén presionado cualquier mensaje y selecciona "Responder". El mensaje original aparece como cita en tu respuesta.',
        ),
        _GuideItem(
          icon: Icons.edit_rounded,
          title: 'Editar un mensaje',
          body: 'Mantén presionado tu propio mensaje y selecciona "Editar". Puedes corregir el texto. El destinatario verá que fue editado.',
        ),
        _GuideItem(
          icon: Icons.delete_rounded,
          title: 'Eliminar un mensaje',
          body: 'Mantén presionado el mensaje → "Eliminar". El mensaje se borra solo de tu vista (no se borra del dispositivo del otro aún en esta versión).',
        ),
        _GuideItem(
          icon: Icons.add_reaction_rounded,
          title: 'Reacciones',
          body: 'Mantén presionado un mensaje y elige una de las 6 reacciones rápidas (❤️👍😂😮😢🙏). La reacción aparece debajo del mensaje.',
        ),
        _GuideItem(
          icon: Icons.star_rounded,
          title: 'Destacar mensajes',
          body: 'Mantén presionado un mensaje → "Destacar" (⭐). Los mensajes destacados se guardan en Ajustes → Mensajes guardados para acceso rápido.',
        ),
        _GuideItem(
          icon: Icons.timer_rounded,
          title: 'Mensajes efímeros',
          body: 'En el chat toca ⋮ → "Mensajes temporales" para activar autodestrucción: 5 min, 1 hora, 1 día o 7 días. Los mensajes se borran solos al vencer el tiempo.',
        ),
        _GuideItem(
          icon: Icons.search_rounded,
          title: 'Buscar dentro del chat',
          body: 'En el chat toca ⋮ → "Buscar". Escribe cualquier palabra para filtrar los mensajes del chat en tiempo real.',
        ),
        _GuideItem(
          icon: Icons.notifications_off_rounded,
          title: 'Silenciar notificaciones',
          body: 'En el chat toca ⋮ → "Silenciar". Las notificaciones de ese chat se desactivan. Toca de nuevo "Activar" para reactivarlas.',
        ),
      ],
    ),
    _GuideSection(
      icon: Icons.people_rounded,
      color: KonectaColors.secondary,
      title: 'Contactos',
      items: [
        _GuideItem(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Agregar contacto por QR',
          body: 'Ve a la pestaña Contactos → toca el ícono de escáner QR (arriba a la derecha). Apunta la cámara al código QR del otro usuario. Al escanearlo, el contacto se agrega automáticamente y puedes iniciar un chat.',
        ),
        _GuideItem(
          icon: Icons.qr_code_rounded,
          title: 'Compartir tu QR',
          body: 'Ve a Chats → ícono QR (arriba) o Ajustes → Mi código QR. Muestra tu código para que otros te escaneen. También puedes tocar "Compartir" para enviarlo por WhatsApp, correo, etc.',
        ),
        _GuideItem(
          icon: Icons.contacts_rounded,
          title: 'Directorio telefónico',
          body: 'En la pestaña Contactos verás tus contactos del teléfono. Si tienen Konecta aparecen en la sección "En Konecta". Los demás aparecen en "Directorio telefónico" con un botón "Invitar" para enviarles el enlace de descarga.',
        ),
        _GuideItem(
          icon: Icons.chat_rounded,
          title: 'Iniciar un chat',
          body: 'Toca un contacto de Konecta → ícono de mensaje 💬. O ve a Chats → botón + (abajo a la derecha) → selecciona un contacto de la lista.',
        ),
        _GuideItem(
          icon: Icons.group_add_rounded,
          title: 'Crear un grupo',
          body: 'En Chats → ⋮ → "Nuevo grupo". Escoge un nombre y selecciona los contactos. Soporta hasta 1024 miembros. Los grupos también van cifrados.',
        ),
      ],
    ),
    _GuideSection(
      icon: Icons.call_rounded,
      color: KonectaColors.accent,
      title: 'Llamadas',
      items: [
        _GuideItem(
          icon: Icons.call_rounded,
          title: 'Llamada de voz',
          body: 'Desde un chat abierto toca el ícono de teléfono 📞 (arriba a la derecha). O desde Contactos → toca el ícono de llamada junto al nombre del contacto.',
        ),
        _GuideItem(
          icon: Icons.videocam_rounded,
          title: 'Videollamada',
          body: 'Desde un chat toca el ícono de cámara 🎥 (arriba). Puedes cambiar entre cámara frontal y trasera durante la llamada con el botón de cambiar cámara.',
        ),
        _GuideItem(
          icon: Icons.lock_rounded,
          title: 'Seguridad de llamadas',
          body: 'Todas las llamadas son P2P (punto a punto) cifradas con WebRTC. El audio y video nunca pasan por ningún servidor — van directamente entre dispositivos.',
        ),
        _GuideItem(
          icon: Icons.history_rounded,
          title: 'Historial de llamadas',
          body: 'La pestaña Llamadas muestra el historial: perdidas (rojo), rechazadas, contestadas y su duración. Toca una entrada para devolver la llamada.',
        ),
      ],
    ),
    _GuideSection(
      icon: Icons.verified_user_rounded,
      color: Color(0xFF7C3AED),
      title: 'Seguridad',
      items: [
        _GuideItem(
          icon: Icons.lock_rounded,
          title: 'PIN de desbloqueo',
          body: 'Konecta se bloquea automáticamente y pide tu PIN de 6 dígitos. Ve a Ajustes → Seguridad → Cambiar PIN para actualizarlo.',
        ),
        _GuideItem(
          icon: Icons.fingerprint_rounded,
          title: 'Huella / Face ID',
          body: 'Activa el desbloqueo biométrico en Ajustes → Seguridad → Biometría. Una vez activado, puedes abrir la app con huella o reconocimiento facial en lugar del PIN.',
        ),
        _GuideItem(
          icon: Icons.crisis_alert_rounded,
          title: 'PIN de pánico',
          body: 'Un PIN alternativo que muestra la app completamente vacía (sin chats, sin contactos). Útil si alguien te obliga a abrir la app. Configúralo en Ajustes → PIN de pánico.',
        ),
        _GuideItem(
          icon: Icons.timer_rounded,
          title: 'Bloqueo automático',
          body: 'En Ajustes → Privacidad → Bloqueo automático elige cuánto tiempo de inactividad necesita la app para bloquearse: Inmediatamente, 1 min, 5 min, 15 min, 1 hora o Nunca.',
        ),
        _GuideItem(
          icon: Icons.screenshot_monitor_rounded,
          title: 'Bloqueo de capturas',
          body: 'En Ajustes → Privacidad activa "Bloqueo de captura de pantalla". Nadie podrá tomar capturas ni grabar la pantalla mientras Konecta esté abierto.',
        ),
        _GuideItem(
          icon: Icons.shield_rounded,
          title: 'Cifrado extremo a extremo',
          body: 'Konecta usa AES-256-GCM con clave derivada del chatId. Ni el relay ni ningún servidor puede leer tus mensajes. En versiones futuras se implementará Double Ratchet completo (Signal Protocol).',
        ),
        _GuideItem(
          icon: Icons.key_rounded,
          title: 'Claves Ed25519',
          body: 'Al registrarte, Konecta genera un par de claves Ed25519 únicas en tu dispositivo. Tu clave privada nunca sale del teléfono. El código QR usa tu clave pública para verificar tu identidad.',
        ),
      ],
    ),
    _GuideSection(
      icon: Icons.settings_rounded,
      color: KonectaColors.primary,
      title: 'Ajustes',
      items: [
        _GuideItem(
          icon: Icons.dark_mode_rounded,
          title: 'Tema oscuro / claro',
          body: 'Ajustes → Apariencia → elige Oscuro, Claro o Sistema (sigue el tema del teléfono). El cambio es inmediato.',
        ),
        _GuideItem(
          icon: Icons.language_rounded,
          title: 'Idioma',
          body: 'Ajustes → Idioma → Español o English. La interfaz completa cambia de idioma sin reiniciar la app.',
        ),
        _GuideItem(
          icon: Icons.account_circle_rounded,
          title: 'Foto de perfil',
          body: 'En Ajustes toca tu avatar (el círculo con tu inicial) → elige "Galería" o "Tomar foto". La imagen se escala a 512×512.',
        ),
        _GuideItem(
          icon: Icons.badge_rounded,
          title: 'Tu ID de Konecta',
          body: 'En Ajustes verás tu ID único (una cadena hexadecimal). Tócalo para copiarlo al portapapeles. Este ID identifica tu cuenta para recibir mensajes.',
        ),
        _GuideItem(
          icon: Icons.star_rounded,
          title: 'Mensajes guardados',
          body: 'Ajustes → Mensajes guardados muestra todos los mensajes que marcaste con ⭐ en cualquier chat. Toca uno para ir al chat original.',
        ),
        _GuideItem(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          body: 'Ajustes → Cuenta → Cerrar sesión. Cierra sesión sin borrar tus mensajes ni claves locales. Al volver a abrir necesitas tu PIN.',
        ),
        _GuideItem(
          icon: Icons.delete_forever_rounded,
          title: 'Eliminar cuenta',
          body: 'Ajustes → Cuenta → Eliminar cuenta. Borra permanentemente tu cuenta, claves criptográficas y todos los datos locales. Esta acción NO se puede deshacer.',
        ),
      ],
    ),
    _GuideSection(
      icon: Icons.info_rounded,
      color: KonectaColors.accent,
      title: 'Acerca de Konecta',
      items: [
        _GuideItem(
          icon: Icons.verified_rounded,
          title: '¿Qué es Konecta?',
          body: 'Konecta es una aplicación de mensajería privada con cifrado de extremo a extremo. Tus mensajes, llamadas y archivos viajan cifrados — nadie, ni siquiera Konecta, puede leerlos.',
        ),
        _GuideItem(
          icon: Icons.cloud_off_rounded,
          title: 'Sin metadatos en la nube',
          body: 'El relay (servidor de enrutamiento) solo ve el ID del destinatario para entregar el mensaje, nunca el contenido. Los mensajes se almacenan únicamente en los dispositivos de los participantes.',
        ),
        _GuideItem(
          icon: Icons.update_rounded,
          title: 'Actualizaciones',
          body: 'Konecta verifica automáticamente si hay una nueva versión al abrir. Si existe, aparece un aviso con el enlace de descarga en GitHub. Las actualizaciones son manuales (APK).',
        ),
        _GuideItem(
          icon: Icons.code_rounded,
          title: 'Creado por',
          body: 'Konecta fue creado por Pedro Espinal. Todos los derechos reservados 2026.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guía de usuario',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              AppVersion.displayVersion,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: KonectaColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _sections.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) return _buildHeader(context, isDark);
                final idx = i - 1;
                final section = _sections[idx];
                final isOpen = _expanded.contains(idx);
                return _buildSection(context, isDark, idx, section, isOpen);
              },
            ),
          ),
          const Divider(height: 0.5),
          const KonectaFooter(showVersion: false),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KonectaColors.primary, KonectaColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guía completa de Konecta',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca cada sección para aprender a usar todas las funciones de la app.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isDark,
    int idx,
    _GuideSection section,
    bool isOpen,
  ) {
    final surfaceColor =
        isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface;
    final borderColor =
        isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header del acordeón
          InkWell(
            onTap: () => setState(() {
              if (isOpen) {
                _expanded.remove(idx);
              } else {
                _expanded.add(idx);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(section.icon, color: section.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${section.items.length} temas',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: borderColor,
                ),
                ...section.items.asMap().entries.map((entry) {
                  final isLast = entry.key == section.items.length - 1;
                  return _buildItem(context, isDark, entry.value, isLast, borderColor);
                }),
              ],
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    bool isDark,
    _GuideItem item,
    bool isLast,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KonectaColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 17, color: KonectaColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 60,
            color: borderColor,
          ),
      ],
    );
  }
}

class _GuideSection {
  final IconData icon;
  final Color color;
  final String title;
  final List<_GuideItem> items;
  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String body;
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}
