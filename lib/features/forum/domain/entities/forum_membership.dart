class ForumMembership {
  const ForumMembership({required this.hasGroup, this.groupId, this.status});

  /// User hiện có nhóm không
  final bool hasGroup;

  /// ID nhóm (nếu có)
  final String? groupId;

  /// 'leader' | 'member' | 'student' | ...
  final String? status;
}
