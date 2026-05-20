import 'package:hive/hive.dart';
import '../models/challenge.dart';

final class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.success() : isValid = true, errorMessage = null;
  const ValidationResult.failure(this.errorMessage) : isValid = false;
}

final class ChallengeService {
  static const String _boxName = 'challenges';

  Box<Map<dynamic, dynamic>> _getBox() {
    return Hive.box<Map<dynamic, dynamic>>(_boxName);
  }

  ValidationResult validateChallenge({
    required String title,
    required int targetMinutes,
  }) {
    if (title.trim().isEmpty) {
      return const ValidationResult.failure('Le titre est obligatoire');
    }
    if (targetMinutes <= 0) {
      return const ValidationResult.failure('La durée doit être supérieure à 0');
    }
    return const ValidationResult.success();
  }

  Future<void> createChallenge({
    required String title,
    required int targetMinutes,
    String? description,
  }) async {
    try {
      final ValidationResult validation = validateChallenge(
        title: title,
        targetMinutes: targetMinutes,
      );
      if (!validation.isValid) {
        throw Exception(validation.errorMessage);
      }

      final Challenge challenge = Challenge.create(
        title: title,
        targetMinutes: targetMinutes,
        description: description,
      );

      final Box<Map<dynamic, dynamic>> box = _getBox();
      await box.put(challenge.id, challenge.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création du défi: $e');
    }
  }

  List<Challenge> getAllChallenges() {
    try {
      final Box<Map<dynamic, dynamic>> box = _getBox();
      final List<Challenge> challenges = <Challenge>[];
      
      for (final Map<dynamic, dynamic> map in box.values) {
        challenges.add(Challenge.fromMap(map));
      }
      
      challenges.sort((Challenge a, Challenge b) => b.createdAt.compareTo(a.createdAt));
      return challenges;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des défis: $e');
    }
  }

  Future<void> toggleComplete(String challengeId) async {
    try {
      final Box<Map<dynamic, dynamic>> box = _getBox();
      final Map<dynamic, dynamic>? map = box.get(challengeId);
      
      if (map == null) {
        throw Exception('Défi introuvable');
      }

      final Challenge challenge = Challenge.fromMap(map);
      final Challenge updated = challenge.copyWith(isCompleted: !challenge.isCompleted);
      await box.put(challengeId, updated.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      final Box<Map<dynamic, dynamic>> box = _getBox();
      await box.delete(challengeId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}