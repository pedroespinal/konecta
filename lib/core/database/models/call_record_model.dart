enum CallDirection { outgoing, incoming }

enum CallOutcome { connected, missed, rejected, failed }

class CallRecord {
  final String id;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final CallDirection direction;
  final CallOutcome outcome;
  final DateTime startedAt;
  final int durationSeconds;

  const CallRecord({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.direction,
    required this.outcome,
    required this.startedAt,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'peer_id': peerId,
        'peer_name': peerName,
        'is_video': isVideo ? 1 : 0,
        'direction': direction.index,
        'outcome': outcome.index,
        'started_at': startedAt.millisecondsSinceEpoch,
        'duration_seconds': durationSeconds,
      };

  factory CallRecord.fromMap(Map<String, dynamic> m) => CallRecord(
        id: m['id'] as String,
        peerId: m['peer_id'] as String,
        peerName: m['peer_name'] as String,
        isVideo: (m['is_video'] as int) == 1,
        direction: CallDirection.values[m['direction'] as int],
        outcome: CallOutcome.values[m['outcome'] as int],
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        durationSeconds: m['duration_seconds'] as int? ?? 0,
      );

  CallRecord copyWith({CallOutcome? outcome, int? durationSeconds}) =>
      CallRecord(
        id: id,
        peerId: peerId,
        peerName: peerName,
        isVideo: isVideo,
        direction: direction,
        outcome: outcome ?? this.outcome,
        startedAt: startedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
      );
}
