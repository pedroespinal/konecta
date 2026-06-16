import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import '../network/message_payload.dart';
import '../network/socket_client.dart';
import 'call_state.dart';

class WebRTCState {
  final CallModel? activeCall;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;

  const WebRTCState({
    this.activeCall,
    this.localStream,
    this.remoteStream,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
  });

  bool get hasActiveCall => activeCall != null &&
      activeCall!.status != CallStatus.ended &&
      activeCall!.status != CallStatus.rejected &&
      activeCall!.status != CallStatus.failed;

  WebRTCState copyWith({
    CallModel? activeCall,
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOff,
    bool clearCall = false,
    bool clearLocal = false,
    bool clearRemote = false,
  }) =>
      WebRTCState(
        activeCall: clearCall ? null : (activeCall ?? this.activeCall),
        localStream: clearLocal ? null : (localStream ?? this.localStream),
        remoteStream: clearRemote ? null : (remoteStream ?? this.remoteStream),
        isMuted: isMuted ?? this.isMuted,
        isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
        isCameraOff: isCameraOff ?? this.isCameraOff,
      );
}

class WebRTCService extends StateNotifier<WebRTCState> {
  final Ref _ref;
  RTCPeerConnection? _pc;
  StreamSubscription? _signalSub;
  final _uuid = const Uuid();

  // Configuracion STUN/TURN — servidor propio en produccion
  static const _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  static const _sdpConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': [],
  };

  WebRTCService(this._ref) : super(const WebRTCState()) {
    _listenForIncomingSignals();
  }

  void _listenForIncomingSignals() {
    final socket = _ref.read(socketProvider.notifier);
    _signalSub = socket.callSignals.listen((signal) async {
      switch (signal.type) {
        case PayloadType.callInvite:
          // Notificar a la UI de llamada entrante via state
          state = state.copyWith(
            activeCall: CallModel(
              callId: signal.callId,
              peerId: signal.from,
              peerName: signal.from,
              isVideo: signal.isVideo,
              isOutgoing: false,
              status: CallStatus.incoming,
              startedAt: DateTime.now(),
            ),
          );
        case PayloadType.callAccept:
          await handleAnswer(signal);
        case PayloadType.callReject:
          handleCallReject();
        case PayloadType.callEnd:
          handleCallEnd();
        case PayloadType.iceCandidate:
          await handleIceCandidate(signal);
        default:
          break;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // API pública
  // ─────────────────────────────────────────────────────────────

  Future<void> startCall({
    required String peerId,
    required String peerName,
    required bool isVideo,
    required String myUserId,
  }) async {
    if (state.hasActiveCall) return;

    final callId = _uuid.v4();
    final call = CallModel(
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      isOutgoing: true,
      status: CallStatus.calling,
      startedAt: DateTime.now(),
    );
    state = state.copyWith(activeCall: call);

    // Obtener media local
    final local = await _getLocalStream(isVideo: isVideo);
    state = state.copyWith(localStream: local);

    // Crear PeerConnection
    await _createPC(callId: callId, myId: myUserId, peerId: peerId);

    // Añadir tracks locales
    for (final track in local.getTracks()) {
      await _pc!.addTrack(track, local);
    }

    // Crear oferta SDP
    final offer = await _pc!.createOffer(_sdpConstraints);
    await _pc!.setLocalDescription(offer);

    // Enviar invitacion + SDP
    _sendSignal(CallSignalPayload(
      type: PayloadType.callInvite,
      from: myUserId,
      to: peerId,
      callId: callId,
      isVideo: isVideo,
      sdp: offer.sdp,
    ));
  }

  Future<void> acceptCall({
    required CallSignalPayload invite,
    required String myUserId,
  }) async {
    state = state.copyWith(
      activeCall: CallModel(
        callId: invite.callId,
        peerId: invite.from,
        peerName: invite.from,
        isVideo: invite.isVideo,
        isOutgoing: false,
        status: CallStatus.connecting,
        startedAt: DateTime.now(),
      ),
    );

    final local = await _getLocalStream(isVideo: invite.isVideo);
    state = state.copyWith(localStream: local);

    await _createPC(
        callId: invite.callId, myId: myUserId, peerId: invite.from);

    for (final track in local.getTracks()) {
      await _pc!.addTrack(track, local);
    }

    // Establecer oferta remota
    await _pc!.setRemoteDescription(
        RTCSessionDescription(invite.sdp, 'offer'));

    // Crear respuesta
    final answer = await _pc!.createAnswer(_sdpConstraints);
    await _pc!.setLocalDescription(answer);

    _sendSignal(CallSignalPayload(
      type: PayloadType.callAccept,
      from: myUserId,
      to: invite.from,
      callId: invite.callId,
      isVideo: invite.isVideo,
      sdp: answer.sdp,
    ));
  }

  void rejectCall({required CallSignalPayload invite, required String myId}) {
    _sendSignal(CallSignalPayload(
      type: PayloadType.callReject,
      from: myId,
      to: invite.from,
      callId: invite.callId,
    ));
    _endCleanup();
  }

  void endCall({required String myId}) {
    final call = state.activeCall;
    if (call == null) return;
    _sendSignal(CallSignalPayload(
      type: PayloadType.callEnd,
      from: myId,
      to: call.peerId,
      callId: call.callId,
    ));
    _endCleanup();
  }

  void toggleMute() {
    final local = state.localStream;
    if (local == null) return;
    final muted = !state.isMuted;
    for (final track in local.getAudioTracks()) {
      track.enabled = !muted;
    }
    state = state.copyWith(isMuted: muted);
  }

  void toggleCamera() {
    final local = state.localStream;
    if (local == null) return;
    final off = !state.isCameraOff;
    for (final track in local.getVideoTracks()) {
      track.enabled = !off;
    }
    state = state.copyWith(isCameraOff: off);
  }

  Future<void> switchCamera() async {
    final local = state.localStream;
    if (local == null) return;
    for (final track in local.getVideoTracks()) {
      await Helper.switchCamera(track);
    }
  }

  void toggleSpeaker() {
    final on = !state.isSpeakerOn;
    Helper.setSpeakerphoneOn(on);
    state = state.copyWith(isSpeakerOn: on);
  }

  // ─────────────────────────────────────────────────────────────
  // Handlers de señalización entrante (llamados desde el provider)
  // ─────────────────────────────────────────────────────────────

  Future<void> handleAnswer(CallSignalPayload payload) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(
        RTCSessionDescription(payload.sdp, 'answer'));
    state = state.copyWith(
      activeCall: state.activeCall?.copyWith(
        status: CallStatus.connected,
        connectedAt: DateTime.now(),
      ),
    );
  }

  Future<void> handleIceCandidate(CallSignalPayload payload) async {
    if (_pc == null || payload.candidate == null) return;
    await _pc!.addCandidate(RTCIceCandidate(
      payload.candidate!,
      payload.sdpMid ?? '',
      payload.sdpMLineIndex ?? 0,
    ));
  }

  void handleCallEnd() {
    _endCleanup();
  }

  void handleCallReject() {
    state = state.copyWith(
      activeCall: state.activeCall?.copyWith(status: CallStatus.rejected),
    );
    _endCleanup();
  }

  // ─────────────────────────────────────────────────────────────
  // Internos
  // ─────────────────────────────────────────────────────────────

  Future<MediaStream> _getLocalStream({required bool isVideo}) async {
    return await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    });
  }

  Future<void> _createPC({
    required String callId,
    required String myId,
    required String peerId,
  }) async {
    _pc = await createPeerConnection(_iceConfig);

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _sendSignal(CallSignalPayload(
        type: PayloadType.iceCandidate,
        from: myId,
        to: peerId,
        callId: callId,
        candidate: candidate.candidate,
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      ));
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        state = state.copyWith(remoteStream: event.streams.first);
        if (state.activeCall?.status == CallStatus.calling ||
            state.activeCall?.status == CallStatus.connecting) {
          state = state.copyWith(
            activeCall: state.activeCall?.copyWith(
              status: CallStatus.connected,
              connectedAt: DateTime.now(),
            ),
          );
        }
      }
    };

    _pc!.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _endCleanup();
      }
    };
  }

  void _sendSignal(CallSignalPayload payload) {
    final socket = _ref.read(socketProvider.notifier);
    socket.send(payload.toJson());
  }

  void _endCleanup() {
    state.localStream?.dispose();
    state.remoteStream?.dispose();
    _pc?.close();
    _pc = null;
    final ended = state.activeCall?.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
    );
    state = WebRTCState(
      activeCall: ended,
      isMuted: false,
      isSpeakerOn: false,
      isCameraOff: false,
    );
  }

  @override
  void dispose() {
    _signalSub?.cancel();
    state.localStream?.dispose();
    state.remoteStream?.dispose();
    _pc?.close();
    super.dispose();
  }
}

final webRTCProvider =
    StateNotifierProvider<WebRTCService, WebRTCState>((ref) {
  return WebRTCService(ref);
});
