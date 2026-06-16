import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus {
  idle,
  calling,     // emisor espera respuesta
  incoming,    // receptor recibio invitacion
  connecting,  // ICE negotiation
  connected,
  ended,
  rejected,
  missed,
  failed,
}

class CallModel {
  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final bool isOutgoing;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;

  const CallModel({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.isOutgoing,
    required this.status,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
  });

  Duration? get duration {
    if (connectedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(connectedAt!);
  }

  String get durationString {
    final d = duration;
    if (d == null) return '';
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  CallModel copyWith({
    CallStatus? status,
    DateTime? connectedAt,
    DateTime? endedAt,
    MediaStream? localStream,
    MediaStream? remoteStream,
  }) =>
      CallModel(
        callId: callId,
        peerId: peerId,
        peerName: peerName,
        isVideo: isVideo,
        isOutgoing: isOutgoing,
        status: status ?? this.status,
        startedAt: startedAt,
        connectedAt: connectedAt ?? this.connectedAt,
        endedAt: endedAt ?? this.endedAt,
      );
}

// Registro en historial de llamadas (guardado en SharedPreferences por simplicidad)
class CallRecord {
  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final bool isOutgoing;
  final bool wasMissed;
  final DateTime at;
  final Duration? duration;

  const CallRecord({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.isOutgoing,
    required this.wasMissed,
    required this.at,
    this.duration,
  });

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'peerId': peerId,
        'peerName': peerName,
        'isVideo': isVideo,
        'isOutgoing': isOutgoing,
        'wasMissed': wasMissed,
        'at': at.millisecondsSinceEpoch,
        'duration': duration?.inSeconds,
      };

  factory CallRecord.fromMap(Map<String, dynamic> m) => CallRecord(
        callId: m['callId'] as String,
        peerId: m['peerId'] as String,
        peerName: m['peerName'] as String,
        isVideo: m['isVideo'] as bool,
        isOutgoing: m['isOutgoing'] as bool,
        wasMissed: m['wasMissed'] as bool,
        at: DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
        duration: m['duration'] != null
            ? Duration(seconds: m['duration'] as int)
            : null,
      );
}
