import 'package:uuid/uuid.dart';

enum TimerMode { stopwatch, countdown }

final class Session {
  final String id;
  final int durationMs;
  final TimerMode type;
  final DateTime date;
  final String? challengeId;

  const Session({
    required this.id,
    required this.durationMs,
    required this.type,
    required this.date,
    this.challengeId,
  });

  factory Session.create({
    required int durationMs,
    required TimerMode type,
    String? challengeId,
  }) {
    return Session(
      id: const Uuid().v4(),
      durationMs: durationMs,
      type: type,
      date: DateTime.now(),
      challengeId: challengeId,
    );
  }

  Session copyWith({
    String? id,
    int? durationMs,
    TimerMode? type,
    DateTime? date,
    String? challengeId,
    bool clearChallengeId = false,  // ← AJOUT
  }) {
    return Session(
      id: id ?? this.id,
      durationMs: durationMs ?? this.durationMs,
      type: type ?? this.type,
      date: date ?? this.date,
      challengeId: clearChallengeId ? null : (challengeId ?? this.challengeId),  // ← CORRECTION
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'durationMs': durationMs,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'challengeId': challengeId,
    };
  }

  factory Session.fromMap(Map<dynamic, dynamic> map) {
    return Session(
      id: map['id'] as String,
      durationMs: map['durationMs'] as int,
      type: TimerMode.values.firstWhere((TimerMode e) => e.name == map['type']),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      challengeId: map['challengeId'] as String?,
    );
  }
}