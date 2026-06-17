import 'package:flutter/material.dart';

abstract final class KonectaColors {
  // ── Marca principal — Teal Esmeralda ─────────────────────────────────────
  static const Color primary = Color(0xFF0891B2);       // Teal-600
  static const Color primaryLight = Color(0xFF22D3EE);  // Cyan-400
  static const Color primaryDark = Color(0xFF0E7490);   // Teal-700

  static const Color secondary = Color(0xFF14B8A6);     // Teal-500
  static const Color secondaryLight = Color(0xFF5EEAD4); // Teal-300
  static const Color secondaryDark = Color(0xFF0F9488);  // Teal-600 dark

  static const Color accent = Color(0xFF10B981);         // Esmeralda-500
  static const Color accentLight = Color(0xFF6EE7B7);    // Esmeralda-300

  // ── Estados ──────────────────────────────────────────────────────────────
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ── Burbujas de chat ─────────────────────────────────────────────────────
  static const Color bubbleSentDark = Color(0xFF0A3547);   // Teal oscuro profundo
  static const Color bubbleReceivedDark = Color(0xFF1A1A26);
  static const Color bubbleSentLight = Color(0xFF0891B2);   // Teal primario
  static const Color bubbleReceivedLight = Color(0xFFF1F5F9);

  // ── Modo OSCURO ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF060B0F);  // Casi negro con tono teal
  static const Color darkSurface = Color(0xFF0D1117);
  static const Color darkSurface2 = Color(0xFF161D25);
  static const Color darkSurface3 = Color(0xFF1E2833);
  static const Color darkSurface4 = Color(0xFF243040);

  // Texto dark mode — WCAG AA/AAA compliant sobre #060B0F
  static const Color darkTextPrimary = Color(0xFFECF4F8);    // ~18:1 contrast
  static const Color darkTextSecondary = Color(0xFFA8C4D0);  // ~8.1:1 contrast ✓
  static const Color darkTextTertiary = Color(0xFF6B8FA0);   // ~4.6:1 contrast ✓

  static const Color darkDivider = Color(0xFF1E2833);
  static const Color darkBorder = Color(0xFF253545);

  // ── Modo CLARO ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF0F9FF);   // Azul muy claro
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFE0F2FE);     // Sky-100
  static const Color lightSurface3 = Color(0xFFBAE6FD);     // Sky-200
  static const Color lightSurface4 = Color(0xFF7DD3FC);     // Sky-300

  static const Color lightTextPrimary = Color(0xFF0C1A21);   // Casi negro con tono teal
  static const Color lightTextSecondary = Color(0xFF374151); // Gris oscuro
  static const Color lightTextTertiary = Color(0xFF6B7280);  // Gris medio

  static const Color lightDivider = Color(0xFFE0F2FE);
  static const Color lightBorder = Color(0xFFBAE6FD);
}
