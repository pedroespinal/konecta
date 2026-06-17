import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message_payload.dart';

enum SocketStatus { disconnected, connecting, connected, error }

class SocketState {
  final SocketStatus status;
  final String? error;
  const SocketState({this.status = SocketStatus.disconnected, this.error});
}

class KonectaSocketClient extends StateNotifier<SocketState> {
  // Actualizar con el URL de Railway después del deploy:
  // wss://<nombre>.up.railway.app/ws
  static const String _relayUrl = 'wss://relay.konecta.app/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectDelay = 2;

  final _messageController = StreamController<MessagePayload>.broadcast();
  final _presenceController = StreamController<PresencePayload>.broadcast();
  final _typingController = StreamController<TypingPayload>.broadcast();
  final _callSignalController = StreamController<CallSignalPayload>.broadcast();

  Stream<MessagePayload> get messages => _messageController.stream;
  Stream<PresencePayload> get presenceUpdates => _presenceController.stream;
  Stream<TypingPayload> get typingEvents => _typingController.stream;
  Stream<CallSignalPayload> get callSignals => _callSignalController.stream;

  KonectaSocketClient() : super(const SocketState());

  Future<void> connect(String userId, String authToken) async {
    if (state.status == SocketStatus.connected ||
        state.status == SocketStatus.connecting) {
      return;
    }

    state = const SocketState(status: SocketStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_relayUrl?userId=$userId&token=$authToken'),
      );

      await _channel!.ready;
      state = const SocketState(status: SocketStatus.connected);
      _reconnectDelay = 2;

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _startPing();
    } catch (e) {
      state = SocketState(status: SocketStatus.error, error: e.toString());
      _scheduleReconnect(userId, authToken);
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = PayloadType.values[map['type'] as int];
      switch (type) {
        case PayloadType.message:
          _messageController.add(MessagePayload.fromJson(raw));
        case PayloadType.presenceUpdate:
          _presenceController.add(PresencePayload(
            userId: map['userId'] as String,
            isOnline: map['isOnline'] as bool,
            lastSeenTimestamp: map['lastSeen'] as int?,
          ));
        case PayloadType.typingIndicator:
          _typingController.add(TypingPayload(
            from: map['from'] as String,
            chatId: map['chatId'] as String,
            isTyping: map['isTyping'] as bool,
          ));
        case PayloadType.pong:
          break;
        case PayloadType.callInvite:
        case PayloadType.callAccept:
        case PayloadType.callReject:
        case PayloadType.callEnd:
        case PayloadType.sdpOffer:
        case PayloadType.sdpAnswer:
        case PayloadType.iceCandidate:
          _callSignalController.add(CallSignalPayload.fromJson(raw));
        default:
          break;
      }
    } catch (_) {}
  }

  void _onError(Object error) {
    state = SocketState(status: SocketStatus.error, error: error.toString());
  }

  void _onDone() {
    state = const SocketState(status: SocketStatus.disconnected);
    _pingTimer?.cancel();
  }

  void send(String payload) {
    if (state.status != SocketStatus.connected) return;
    _channel?.sink.add(payload);
  }

  void sendMessage(MessagePayload msg) => send(msg.toJson());
  void sendTyping(TypingPayload t) => send(t.toJson());

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send('{"type":${PayloadType.ping.index}}');
    });
  }

  void _scheduleReconnect(String userId, String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () {
      _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60);
      connect(userId, token);
    });
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    state = const SocketState(status: SocketStatus.disconnected);
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _presenceController.close();
    _typingController.close();
    _callSignalController.close();
    super.dispose();
  }
}

final socketProvider =
    StateNotifierProvider<KonectaSocketClient, SocketState>(
  (_) => KonectaSocketClient(),
);
