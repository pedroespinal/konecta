import 'package:flutter/material.dart';
import 'l10n_es.dart';
import 'l10n_en.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _KonectaLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  // ── Generales ─────────────────────────────────────────────────────────────
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get close;
  String get back;
  String get next;
  String get loading;
  String get error;
  String get retry;
  String get search;
  String get settings;
  String get version;
  String get copyright;

  // ── Navegacion ────────────────────────────────────────────────────────────
  String get navChats;
  String get navCalls;
  String get navStories;
  String get navContacts;

  // ── Chats ────────────────────────────────────────────────────────────────
  String get chats;
  String get newChat;
  String get newGroup;
  String get typeMessage;
  String get send;
  String get delivered;
  String get read;
  String get online;
  String get lastSeen;
  String get typing;
  String get recording;
  String get encryptedMsg;

  // ── Llamadas ─────────────────────────────────────────────────────────────
  String get calls;
  String get voiceCall;
  String get videoCall;
  String get callEnded;
  String get missedCall;
  String get incomingCall;

  // ── Configuracion ─────────────────────────────────────────────────────────
  String get profile;
  String get privacy;
  String get security;
  String get notifications;
  String get storage;
  String get appearance;
  String get language;
  String get darkMode;
  String get lightMode;
  String get systemMode;
  String get backup;
  String get about;

  // ── Seguridad ─────────────────────────────────────────────────────────────
  String get biometricUnlock;
  String get screenshotProtection;
  String get twoFactorAuth;
  String get disappearingMessages;

  // ── Acerca de ────────────────────────────────────────────────────────────
  String get aboutTitle;
  String get buildNumber;
  String get userGuide;
  String get licenses;

  // ── Errores ──────────────────────────────────────────────────────────────
  String get networkError;
  String get serverError;
  String get unknownError;
}

class _KonectaLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _KonectaLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return L10nEn();
      case 'es':
      default:
        return L10nEs();
    }
  }

  @override
  bool shouldReload(_KonectaLocalizationsDelegate old) => false;
}
