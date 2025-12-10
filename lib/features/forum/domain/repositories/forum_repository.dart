import '../entities/forum_membership.dart';
import '../entities/forum_post.dart';

abstract class ForumRepository {
  /// Lấy membership hiện tại (để biết user có groupId không)
  Future<ForumMembership?> fetchMembership(String accessToken);

  /// Danh sách bài post tuyển thành viên (recruitment posts)
  Future<List<ForumPost>> fetchRecruitmentPosts(String accessToken);

  /// Danh sách bài post cá nhân (sinh viên tìm nhóm)
  Future<List<ForumPost>> fetchPersonalPosts(String accessToken);

  /// Tạo recruitment post
  Future<ForumPost> createRecruitmentPost(
    String accessToken, {
    required String groupId,
    required String title,
    required String description,
    required String positionNeeded,
    DateTime? expiresAt,
    List<String>? skills,
  });

  /// Tạo personal post
  Future<ForumPost> createPersonalPost(
    String accessToken, {
    required String title,
    required String description,
    List<String>? skills,
  });

  /// Apply vào 1 recruitment post
  Future<void> applyToRecruitmentPost(
    String accessToken, {
    required String postId,
    required String message,
  });
}
