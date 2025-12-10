import '../../domain/entities/forum_post.dart';

class ForumPostModel extends ForumPost {
  const ForumPostModel({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    super.groupId,
    super.groupName,
    super.authorId,
    super.authorName,
    super.authorAvatarUrl,
    super.positionNeeded,
    super.skills = const [],
    super.createdAt,
    super.expiresAt,
    super.hasApplied = false,
    super.myApplicationStatus,
    super.applicationsCount = 0,
    super.currentMembers,
    super.maxMembers,
  });

  /// Parse từ JSON BE trả về
  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    // skills có thể là List<String> hoặc string CSV
    final dynamic rawSkills = json['skills'];
    final List<String> skills = [];
    if (rawSkills is List) {
      skills.addAll(rawSkills.whereType<String>());
    } else if (rawSkills is String) {
      skills.addAll(
        rawSkills.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    String type = (json['type'] ?? json['postType'] ?? '')
        .toString()
        .toLowerCase();
    if (type.isEmpty) {
      // fallback theo endpoint
      type = (json['isGroup'] == true) ? 'group_hiring' : 'individual';
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final groupData = json['group'];
    String? groupName;
    int? maxMembers;
    int? currentMembers;

    if (groupData is Map<String, dynamic>) {
      groupName = groupData['name'] as String? ?? json['groupName'] as String?;
      maxMembers = parseInt(
        groupData['maxMembers'] ??
            groupData['memberLimit'] ??
            groupData['max_members'],
      );
      currentMembers = parseInt(
        json['currentMembers'] ??
            groupData['currentMembers'] ??
            groupData['memberCount'] ??
            groupData['membersCount'],
      );
    } else {
      groupName = json['groupName'] as String?;
      maxMembers = parseInt(json['maxMembers']);
      currentMembers = parseInt(json['currentMembers']);
    }

    String? leaderName;
    String? leaderAvatarUrl;
    if (groupData is Map<String, dynamic>) {
      groupName = groupData['name'] as String?;
      // Lấy tên và avatar leader từ group.leader
      final leaderData = groupData['leader'];
      if (leaderData is Map<String, dynamic>) {
        leaderName = leaderData['displayName'] as String?;
        leaderAvatarUrl = leaderData['avatarUrl'] as String?;
      }
    } else {
      groupName = json['groupName'] as String?;
    }

    return ForumPostModel(
      id: (json['id'] ?? '').toString(),
      type: type,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      groupId: json['groupId']?.toString(),
      groupName: groupName,
      authorId: json['ownerId']?.toString() ?? json['userId']?.toString(),
      authorName:
          leaderName ??
          json['ownerName'] as String? ??
          json['authorName'] as String? ??
          '',
      authorAvatarUrl: leaderAvatarUrl ?? json['authorAvatarUrl'] as String?,
      positionNeeded:
          json['position_needed'] as String? ??
          json['positionNeeded'] as String?,
      skills: skills,
      createdAt: parseDate(json['createdAt']),
      expiresAt:
          parseDate(json['expiresAt']) ??
          parseDate(json['applicationDeadline']),
      hasApplied: json['hasApplied'] as bool? ?? false,
      myApplicationStatus: json['myApplicationStatus'] as String?,
      applicationsCount: json['applicationsCount'] is int
          ? json['applicationsCount'] as int
          : int.tryParse('${json['applicationsCount'] ?? 0}') ?? 0,
      currentMembers: currentMembers,
      maxMembers: maxMembers,
    );
  }

  /// Dùng khi tạo post
  Map<String, dynamic> toJsonForCreateRecruitment() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      if (positionNeeded != null) 'position_needed': positionNeeded,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (skills.isNotEmpty) 'skills': skills,
    };
  }

  Map<String, dynamic> toJsonForCreatePersonal() {
    return {
      'title': title,
      'description': description,
      if (skills.isNotEmpty) 'skills': skills.join(','),
    };
  }
}
