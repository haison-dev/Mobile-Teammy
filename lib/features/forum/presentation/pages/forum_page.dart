import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/forum_remote_data_source.dart';
import '../../data/repositories/forum_repository_impl.dart';
import '../../domain/entities/forum_membership.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

enum _ForumTab { groups, individuals }

class ForumPage extends StatefulWidget {
  const ForumPage({super.key, required this.session, required this.language});

  final AuthSession session;
  final AppLanguage language;

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late final ForumRepository _repository;

  _ForumTab _tab = _ForumTab.groups;
  ForumMembership? _membership;

  bool _loading = true;
  String? _error;

  final List<ForumPost> _groupPosts = [];
  final List<ForumPost> _individualPosts = [];

  final _searchController = TextEditingController();

  // Modal Apply state
  ForumPost? _applyingPost;
  String? _selectedPosition;
  final _messageController = TextEditingController();
  bool _isApplying = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void initState() {
    super.initState();
    _repository = ForumRepositoryImpl(
      remoteDataSource: ForumRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.accessToken;
      final membership = await _repository.fetchMembership(token);
      final groups = await _repository.fetchRecruitmentPosts(token);
      final individuals = await _repository.fetchPersonalPosts(token);

      if (!mounted) return;
      setState(() {
        _membership = membership;
        _groupPosts
          ..clear()
          ..addAll(groups);
        _individualPosts
          ..clear()
          ..addAll(individuals);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ForumPost> get _visiblePosts {
    final src = _tab == _ForumTab.groups ? _groupPosts : _individualPosts;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(src);

    return src
        .where(
          (p) =>
              p.title.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query) ||
              p.skills.any((s) => s.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  bool _isClosed(ForumPost post) {
    if (post.expiresAt == null) return false;
    return post.expiresAt!.isBefore(DateTime.now());
  }

  // TODO: sau nếu muốn dùng màn tạo post chi tiết thì thay SnackBar bằng Navigator.push
  Future<void> _openCreateRecruitmentPost() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'Màn tạo bài tuyển sẽ được implement sau.',
            'Create recruitment post screen will be implemented later.',
          ),
        ),
      ),
    );
  }

  Future<void> _openCreatePersonalPost() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'Màn tạo bài cá nhân sẽ được implement sau.',
            'Create personal post screen will be implemented later.',
          ),
        ),
      ),
    );
  }

  Future<void> _showApplyModal(ForumPost post) async {
    if (post.hasApplied) {
      // Nếu đã apply, hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Bạn đã nộp đơn cho bài này rồi',
              'You have already applied to this post',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _applyingPost = post;
      _selectedPosition = null;
      _messageController.clear();
    });

    final positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Ứng tuyển vào nhóm', 'Apply to group'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${_t('Ứng tuyển vào:', 'Applying to:')} ${post.groupName ?? post.title}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position selector
              if (positions.isNotEmpty) ...[
                Text(
                  _t(
                    'Vị trí bạn muốn ứng tuyển',
                    'Position you\'re applying for',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPosition,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: Text(_t('Chọn vị trí', 'Select a role')),
                  items: positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPosition = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              // Message
              Text(
                _t(
                  'Tại sao bạn muốn tham gia dự án này?',
                  'Why you want to join this project?',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _t('Nhập mô tả...', 'Enter description'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _applyingPost = null);
              Navigator.of(context).pop();
            },
            child: Text(_t('Huỷ', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: _isApplying
                ? null
                : () async {
                    final position = _selectedPosition;
                    final message = _messageController.text.trim();

                    if ((positions.isNotEmpty && position == null) ||
                        message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t(
                              'Vui lòng điền đầy đủ thông tin',
                              'Please fill all fields',
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => _isApplying = true);

                    Navigator.of(context).pop();

                    // Gửi request apply
                    try {
                      final fullMessage =
                          positions.isNotEmpty && position != null
                          ? '$position - $message'
                          : message;

                      await _repository.applyToRecruitmentPost(
                        widget.session.accessToken,
                        postId: post.id,
                        message: fullMessage,
                      );

                      if (!mounted) return;

                      // Reload to update status
                      await _loadAll();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t(
                              'Đã gửi yêu cầu tham gia nhóm',
                              'Application sent',
                            ),
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t(
                              'Không thể gửi yêu cầu: $e',
                              'Failed to apply: $e',
                            ),
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _applyingPost = null;
                          _isApplying = false;
                        });
                      }
                    }
                  },
            child: _isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_t('Gửi', 'Submit')),
          ),
        ],
      ),
    );

    setState(() => _applyingPost = null);
  }

  Future<void> _openDetail(ForumPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForumPostDetailPage(
          session: widget.session,
          language: widget.language,
          post: post,
          repository: _repository,
        ),
      ),
    );
  }

  Widget _buildTabButton(_ForumTab tab, String label) {
    final bool selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF020617) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final bool isGroup = post.type == 'group_hiring';
    final closed = _isClosed(post);
    final statusLabel = closed ? _t('closed', 'closed') : _t('open', 'open');
    final statusColor = closed
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF16A34A);

    final List<String> positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String authorName = (post.authorName?.isNotEmpty ?? false)
        ? post.authorName!
        : 'Leader';
    final String avatarInitial = authorName.trim().isNotEmpty
        ? authorName.trim().characters.first.toUpperCase()
        : 'L';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + status + stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${post.applicationsCount} ${_t('Applications', 'Applications')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (post.expiresAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_t('Due', 'Due')}: ${_formatDateShort(post.expiresAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // avatar + meta
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (post.authorAvatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(post.authorAvatarUrl!)
                    : null,
                child: (post.authorAvatarUrl?.isNotEmpty ?? false)
                    ? null
                    : Text(
                        avatarInitial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '• ${_t('leader', 'leader')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if ((post.groupName ?? '').isNotEmpty)
                      Text(
                        '• ${post.groupName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (post.createdAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 4,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDateShort(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // description
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // positions
          if (positions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Positions Needed:', 'Positions Needed:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: positions
                      .map(
                        (p) => Chip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE0ECFF),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          if (positions.isNotEmpty) const SizedBox(height: 8),

          // skills
          if (post.skills.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Skills:', 'Skills:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: post.skills
                      .map(
                        (s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE5EDFF),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              if (post.currentMembers != null && post.maxMembers != null)
                Text(
                  widget.language == AppLanguage.vi
                      ? '${post.currentMembers}/${post.maxMembers} thành viên'
                      : '${post.currentMembers}/${post.maxMembers} members',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              const Spacer(),
              // Hiển thị trạng thái application nếu đã apply
              if (post.hasApplied && post.myApplicationStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: post.myApplicationStatus == 'accepted'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : post.myApplicationStatus == 'rejected'
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.myApplicationStatus == 'accepted'
                        ? _t('Đã chấp nhận', 'Accepted')
                        : post.myApplicationStatus == 'rejected'
                        ? _t('Đã từ chối', 'Rejected')
                        : _t('Đang chờ', 'Pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: post.myApplicationStatus == 'accepted'
                          ? const Color(0xFF10B981)
                          : post.myApplicationStatus == 'rejected'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Nút Apply (chỉ hiển nếu chưa apply và là group hiring)
              if (isGroup && !post.hasApplied) ...[
                ElevatedButton(
                  onPressed: () => _showApplyModal(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                  child: Text(
                    _t('Apply', 'Apply'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: () => _openDetail(post),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  _t('View Details', 'View Details'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    final posts = _visiblePosts;

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Error: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadAll,
              child: Text(_t('Thử lại', 'Retry')),
            ),
          ),
        ],
      );
    }

    if (posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _tab == _ForumTab.groups
                  ? _t(
                      'Chưa có bài tuyển nào.\nHãy là người đầu tiên tạo bài tuyển nhóm.',
                      'No recruitment posts yet.\nBe the first to create a group post.',
                    )
                  : _t(
                      'Chưa có sinh viên nào đăng bài tìm nhóm.',
                      'No students have posted personal profiles yet.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: posts.map(_buildPostCard).toList(),
    );
  }

  Widget _buildHeaderSection() {
    final totalRecruitment = _groupPosts.length;
    final totalPersonal = _individualPosts.length;

    return Padding(
      // top = 0 để dính sát AppBar giống màn Nhóm
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            _t('Recruitment Forum', 'Recruitment Forum'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'Post recruitment opportunities or showcase your profile to find the perfect team match. Connect with students and groups across all departments.',
              'Post recruitment opportunities or showcase your profile to find the perfect team match. Connect with students and groups across all departments.',
            ),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // nút Create + stats
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (_tab == _ForumTab.groups) {
                    _openCreateRecruitmentPost();
                  } else {
                    _openCreatePersonalPost();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(
                  _tab == _ForumTab.groups
                      ? _t('Create group post', 'Create group post')
                      : _t('Create personal post', 'Create personal post'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalRecruitment ${_t('recruitment post', 'recruitment post')}${totalRecruitment == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalPersonal ${_t('student profile', 'student profile')}${totalPersonal == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: _t(
                'Search posts by project, skills',
                'Search posts by project, skills',
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  _ForumTab.groups,
                  _t('Post Group', 'Post Group'),
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  _ForumTab.individuals,
                  _t('Post Personal', 'Post Personal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF4CB065),
              onRefresh: _loadAll,
              child: _buildPostList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ForumPostDetailPage extends StatefulWidget {
  const ForumPostDetailPage({
    super.key,
    required this.session,
    required this.language,
    required this.post,
    required this.repository,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumPost post;
  final ForumRepository repository;

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  bool _applying = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _apply() async {
    if (widget.post.type != 'group_hiring') return;

    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Ứng tuyển vào nhóm', 'Apply to group')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                'Viết lời nhắn ngắn cho leader.',
                'Write a short message to the leader.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _t(
                  'Ví dụ: Em muốn apply vị trí FE...',
                  'Example: I would like to join as FE...',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<String>(null),
            child: Text(_t('Huỷ', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop<String>(controller.text.trim()),
            child: Text(_t('Gửi', 'Send')),
          ),
        ],
      ),
    );

    if (message == null || message.isEmpty) return;

    setState(() => _applying = true);
    try {
      await widget.repository.applyToRecruitmentPost(
        widget.session.accessToken,
        postId: widget.post.id,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Đã gửi yêu cầu tham gia nhóm', 'Application sent')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Không thể gửi yêu cầu: $e', 'Failed to apply: $e')),
        ),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final memberText = (post.currentMembers != null && post.maxMembers != null)
        ? (widget.language == AppLanguage.vi
              ? '${post.currentMembers}/${post.maxMembers} thành viên'
              : '${post.currentMembers}/${post.maxMembers} members')
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_t('Post details', 'Post details'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (post.authorName != null && post.authorName!.isNotEmpty)
              Text(
                post.authorName!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            const SizedBox(height: 12),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (post.positionNeeded != null && post.positionNeeded!.isNotEmpty)
              Text(
                _t(
                  'Vị trí cần tuyển: ${post.positionNeeded}',
                  'Position needed: ${post.positionNeeded}',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 12),
            if (post.skills.isNotEmpty) ...[
              Text(
                _t('Skills:', 'Skills:'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: -4,
                children: post.skills
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFE5EDFF),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            if (memberText != null)
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    memberText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            if (post.type == 'group_hiring')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applying ? null : _apply,
                  child: _applying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_t('Apply to this group', 'Apply to this group')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
