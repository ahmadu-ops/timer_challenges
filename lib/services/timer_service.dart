import 'dart:async';

enum TimerState { idle, running, paused, finished }

final class TimerService {
  static const int _tickIntervalMs = 10;
  
  Timer? _timer;
  int _elapsedMs = 0;
  int _targetMs = 0;

  int get elapsedMs => _elapsedMs;
  int get targetMs => _targetMs;
  int get remainingMs => _targetMs > 0 ? (_targetMs - _elapsedMs).clamp(0, _targetMs) : 0;

  void startStopwatch() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (Timer timer) {
        _elapsedMs += _tickIntervalMs;
      },
    );
  }

  void startCountdown({required int targetMs}) {
    _timer?.cancel();
    _targetMs = targetMs;
    _elapsedMs = 0;
    _timer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (Timer timer) {
        _elapsedMs += _tickIntervalMs;
        if (_elapsedMs >= _targetMs) {
          timer.cancel();
        }
      },
    );
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    _elapsedMs = 0;
    _targetMs = 0;
  }

  void dispose() {
    _timer?.cancel();
  }

  bool isFinished() {
    return _targetMs > 0 && _elapsedMs >= _targetMs;
  }

  static String formatTime(int milliseconds) {
    final int totalSeconds = milliseconds ~/ 1000;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    final int ms = (milliseconds % 1000) ~/ 10;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}:'
           '${ms.toString().padLeft(2, '0')}';
  }
}