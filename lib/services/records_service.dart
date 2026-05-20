import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

final class RecordsService {
  static const String _sessionsBoxName = 'sessions';
  static const String _lastSessionDateKey = 'last_session_date';
  static const String _currentStreakKey = 'current_streak';
  static const int _maxHistoryItems = 20;

  Box<Map<dynamic, dynamic>> _getBox() {
    return Hive.box<Map<dynamic, dynamic>>(_sessionsBoxName);
  }

  Future<void> saveSession(Session session) async {
    try {
      final Box<Map<dynamic, dynamic>> box = _getBox();
      await box.put(session.id, session.toMap());
      await _updateStreak(session.date);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  List<Session> getHistory() {
    try {
      final Box<Map<dynamic, dynamic>> box = _getBox();
      final List<Session> sessions = <Session>[];
      
      for (final Map<dynamic, dynamic> map in box.values) {
        sessions.add(Session.fromMap(map));
      }
      
      sessions.sort((Session a, Session b) => b.date.compareTo(a.date));
      return sessions.take(_maxHistoryItems).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  int? getBestTime() {
    try {
      final List<Session> sessions = getHistory();
      final List<Session> stopwatchSessions = sessions
          .where((Session s) => s.type == TimerMode.stopwatch)
          .toList();
      
      if (stopwatchSessions.isEmpty) {
        return null;
      }

      int best = stopwatchSessions.first.durationMs;
      for (final Session session in stopwatchSessions) {
        if (session.durationMs > best) {
          best = session.durationMs;
        }
      }
      return best;
    } catch (e) {
      throw Exception('Erreur lors du calcul: $e');
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_currentStreakKey) ?? 0;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du streak: $e');
    }
  }

  Future<void> _updateStreak(DateTime sessionDate) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastDateStr = prefs.getString(_lastSessionDateKey);
      final int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

      final DateTime today = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
      );

      if (lastDateStr == null) {
        await prefs.setString(_lastSessionDateKey, today.toIso8601String());
        await prefs.setInt(_currentStreakKey, 1);
        return;
      }

      final DateTime lastDate = DateTime.parse(lastDateStr);
      final DateTime lastDateNormalized = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );

      final int daysDifference = today.difference(lastDateNormalized).inDays;

      if (daysDifference == 0) {
        return;
      } else if (daysDifference == 1) {
        await prefs.setString(_lastSessionDateKey, today.toIso8601String());
        await prefs.setInt(_currentStreakKey, currentStreak + 1);
      } else {
        await prefs.setString(_lastSessionDateKey, today.toIso8601String());
        await prefs.setInt(_currentStreakKey, 1);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du streak: $e');
    }
  }
}