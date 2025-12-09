import '../../domain/entities/skill.dart';

class SkillModel extends Skill {
  const SkillModel({
    required super.skillId,
    required super.skillName,
    required super.category,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      skillId: (json['skillId'] ?? json['token'] ?? '') as String,
      skillName: (json['skillName'] ?? json['token'] ?? '') as String,
      category: (json['category'] ?? json['role'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'skillName': skillName,
      'category': category,
    };
  }
}
