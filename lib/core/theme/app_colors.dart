import 'package:flutter/material.dart';

abstract final class KonectaColors {
  // ── Marca principal ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);       // Violeta Konecta
  static const Color primaryLight = Color(0xFFA855F7);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color secondary = Color(0xFF06B6D4);     // Cian
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color secondaryDark = Color(0xFF0891B2);

  static const Color accent = Color(0xFF10B981);        // Esmeralda (estado en linea)
  static const Color accentLight = Color(0xFF6EE7B7);

  // ── Estados ──────────────────────────────────────────────────────────────
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ── Burbujas de chat ─────────────────────────────────────────────────────
  static const Color bubbleSentDark = Color(0xFF4C1D95);
  static const Color bubbleReceivedDark = Color(0xFF1E1E2E);
  static const Color bubbleSentLight = Color(0xFF7C3AED);
  static const Color bubbleReceivedLight = Color(0xFFF3F4F6);

  // ── Modo OSCURO ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF131318);
  static const Color darkSurface2 = Color(0xFF1A1A22);
  static const Color darkSurface3 = Color(0xFF22222E);
  static const Color darkSurface4 = Color(0xFF2A2A3A);

  static const Color darkTextPrimary = Color(0xFFF1F0FF);
  static const Color darkTextSecondary = Color(0xFF8B8BA7);
  static const Color darkTextTertiary = Color(0xFF55556A);

  static const Color darkDivider = Color(0xFF2A2A3A);
  static const Color darkBorder = Color(0xFF333348);

  // ── Modo CLARO ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0EFF8);
  static const Color lightSurface3 = Color(0xFFE8E7F2);
  static const Color lightSurface4 = Color(0xFFDEDDF0);

  static const Color lightTextPrimary = Color(0xFF1A1929);
  static const Color lightTextSecondary = Color(0xFF5B5A7A);
  static const Color lightTextTertiary = Color(0xFF9B9AB8);

  static const Color lightDivider = Color(0xFFE2E1F0);
  static const Color lightBorder = Color(0xFFCECDE8);
}
