import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../models/session.dart';
import '../services/timer_service.dart';
import '../services/challenge_service.dart';
import '../services/records_service.dart';

// ============ TIMER STATE ============

final class TimerNotifierState {
  final TimerState state;
  final TimerMode mode;
  final int elapsedMs;
  final int targetMs;
  final String? linkedChallengeId;

  const TimerNotifierState({
    required this.state,
    required this.mode,
    required this.elapsedMs,
    required this.targetMs,
    this.linkedChallengeId,
  });

  TimerNotifierState copyWith({
    TimerState? state,
    TimerMode? mode,
    int? elapsedMs,
    int? targetMs,
    String? linkedChallengeId,
    bool clearLinkedChallenge = false,  // ← AJOUT
  }) {
    return TimerNotifierState(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      targetMs: targetMs ?? this.targetMs,
      linkedChallengeId: clearLinkedChallenge ? null : (linkedChallengeId ?? this.linkedChallengeId),  // ← CORRECTION
    );
  }
}

class TimerNotifier extends StateNotifier<TimerNotifierState> {
  TimerNotifier()
      : _timerService = TimerService(),
        super(const TimerNotifierState(
          state: TimerState.idle,
          mode: TimerMode.stopwatch,
          elapsedMs: 0,
          targetMs: 60000,
        )) {
    _startTicker();
  }

  final TimerService _timerService;
  Timer? _ticker;

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      if (state.state == TimerState.running) {
        final bool wasFinished = _timerService.isFinished();
        state = state.copyWith(
          elapsedMs: _timerService.elapsedMs,
          state: wasFinished ? TimerState.finished : TimerState.running,
        );
      }
    });
  }

  void setMode(TimerMode mode) {
    if (state.state != TimerState.idle) return;
    state = state.copyWith(mode: mode);
  }

  void setTargetMinutes(int minutes) {
    if (state.state != TimerState.idle) return;
    state = state.copyWith(targetMs: minutes * 60 * 1000);
  }

  void setTargetMs(int ms) {
    if (state.state != TimerState.idle) return;
    state = state.copyWith(targetMs: ms.clamp(0, 86400000));
  }

  void linkChallenge(String? challengeId) {
    if (challengeId == null) {
      state = state.copyWith(clearLinkedChallenge: true);  // ← CORRECTION
    } else {
      state = state.copyWith(linkedChallengeId: challengeId);
    }
  }

  void start() {
    if (state.mode == TimerMode.stopwatch) {
      _timerService.startStopwatch();
    } else {
      if (state.targetMs <= 0) return;
      _timerService.startCountdown(targetMs: state.targetMs);
    }
    state = state.copyWith(state: TimerState.running);
  }

  void pause() {
    _timerService.pause();
    state = state.copyWith(state: TimerState.paused);
  }

  void reset() {
    _timerService.reset();
    state = state.copyWith(
      state: TimerState.idle,
      elapsedMs: 0,
    );
  }

  Future<void> saveSession(RecordsService recordsService) async {
    if (state.elapsedMs == 0) return;

    final Session session = Session.create(
      durationMs: state.elapsedMs,
      type: state.mode,
      challengeId: state.linkedChallengeId,
    );

    await recordsService.saveSession(session);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timerService.dispose();
    super.dispose();
  }
}

final StateNotifierProvider<TimerNotifier, TimerNotifierState> timerProvider =
    StateNotifierProvider<TimerNotifier, TimerNotifierState>(
  (Ref ref) => TimerNotifier(),
);

// ============ CHALLENGES STATE ============

class ChallengesNotifier extends StateNotifier<List<Challenge>> {
  ChallengesNotifier() : _service = ChallengeService(), super(<Challenge>[]) {
    loadChallenges();
  }

  final ChallengeService _service;

  void loadChallenges() {
    try {
      state = _service.getAllChallenges();
    } catch (e) {
      state = <Challenge>[];
    }
  }

  Future<void> createChallenge({
    required String title,
    required int targetMinutes,
    String? description,
  }) async {
    await _service.createChallenge(
      title: title,
      targetMinutes: targetMinutes,
      description: description,
    );
    loadChallenges();
  }

  Future<void> toggleComplete(String id) async {
    await _service.toggleComplete(id);
    loadChallenges();
  }

  Future<void> deleteChallenge(String id) async {
    await _service.deleteChallenge(id);
    loadChallenges();
  }
}

final StateNotifierProvider<ChallengesNotifier, List<Challenge>> challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<Challenge>>(
  (Ref ref) => ChallengesNotifier(),
);

// ============ RECORDS STATE ============

final class RecordsState {
  final List<Session> history;
  final int? bestTimeMs;
  final int currentStreak;
  final Map<String, int> bestTimePerChallenge;  // ← AJOUT
  final Map<String, int> sessionsPerChallenge;  // ← AJOUT

  const RecordsState({
    required this.history,
    this.bestTimeMs,
    required this.currentStreak,
    this.bestTimePerChallenge = const <String, int>{},  // ← AJOUT
    this.sessionsPerChallenge = const <String, int>{},  // ← AJOUT
  });
}

class RecordsNotifier extends StateNotifier<RecordsState> {
  RecordsNotifier()
      : _service = RecordsService(),
        super(const RecordsState(
          history: <Session>[],
          currentStreak: 0,
        )) {
    loadRecords();
  }

  final RecordsService _service;

  Future<void> loadRecords() async {
    try {
      final List<Session> history = _service.getHistory();
      final int? bestTime = _service.getBestTime();
      final int streak = await _service.getCurrentStreak();
      final Map<String, int> bestPerChallenge = _service.getBestTimePerChallenge();  // ← AJOUT
      final Map<String, int> sessionsCount = _service.getSessionsPerChallenge();  // ← AJOUT

      state = RecordsState(
        history: history,
        bestTimeMs: bestTime,
        currentStreak: streak,
        bestTimePerChallenge: bestPerChallenge,  // ← AJOUT
        sessionsPerChallenge: sessionsCount,  // ← AJOUT
      );
    } catch (e) {
      state = const RecordsState(
        history: <Session>[],
        currentStreak: 0,
      );
    }
  }
}

final StateNotifierProvider<RecordsNotifier, RecordsState> recordsProvider =
    StateNotifierProvider<RecordsNotifier, RecordsState>(
  (Ref ref) => RecordsNotifier(),
);

// ============ SERVICES PROVIDERS ============

final Provider<RecordsService> recordsServiceProvider = Provider<RecordsService>(
  (Ref ref) => RecordsService(),
);