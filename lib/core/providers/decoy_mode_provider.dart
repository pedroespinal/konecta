import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuando es true, la app muestra estado vacío (modo decoy / PIN de pánico).
/// Se activa cuando el usuario ingresa el PIN de pánico en la pantalla de bloqueo.
/// Se resetea al cerrar sesión o al autenticarse con el PIN real.
final decoyModeProvider = StateProvider<bool>((ref) => false);
