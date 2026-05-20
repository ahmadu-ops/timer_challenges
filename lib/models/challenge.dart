import 'package:uuid/uuid.dart';

final class Challenge {
  final String id;
  final String title;
  final int targetMinutes;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    required this.title,
    required this.targetMinutes,
    this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  factory Challenge.create({
    required String title,
    required int targetMinutes,
    String? description,
  }) {
    return Challenge(
      id: const Uuid().v4(),
      title: title,
      targetMinutes: targetMinutes,
      description: description,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  Challenge copyWith({
    String? id,
    String? title,
    int? targetMinutes,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'targetMinutes': targetMinutes,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Challenge.fromMap(Map<dynamic, dynamic> map) {
    return Challenge(
      id: map['id'] as String,
      title: map['title'] as String,
      targetMinutes: map['targetMinutes'] as int,
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}