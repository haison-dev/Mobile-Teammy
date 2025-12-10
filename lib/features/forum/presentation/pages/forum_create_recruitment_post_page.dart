import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/forum_membership.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

class ForumCreateRecruitmentPostPage extends StatefulWidget {
  const ForumCreateRecruitmentPostPage({
    super.key,
    required this.session,
    required this.language,
    required this.repository,
    this.membership,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumRepository repository;
  final ForumMembership? membership;

  @override
  State<ForumCreateRecruitmentPostPage> createState() =>
      _ForumCreateRecruitmentPostPageState();
}

class _ForumCreateRecruitmentPostPageState
    extends State<ForumCreateRecruitmentPostPage> {
  final _formKey = GlobalKey<FormState>();

  final _groupIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();
  final _skillsController = TextEditingController();

  DateTime? _expiresAt;
  bool _submitting = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void initState() {
    super.initState();
    if (widget.membership?.groupId != null) {
      _groupIdController.text = widget.membership!.groupId!;
    }
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _parseSkills() {
    return _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final post = await widget.repository.createRecruitmentPost(
        widget.session.accessToken,
        groupId: _groupIdController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        positionNeeded: _positionController.text.trim(),
        expiresAt: _expiresAt,
        skills: _parseSkills(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Tạo bài tuyển thành công', 'Post created'))),
      );
      Navigator.of(context).pop<ForumPost>(post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Không thể tạo bài tuyển: $e', 'Failed to create post: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = widget.membership?.status == 'leader';

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Tạo bài tuyển thành viên', 'Create recruitment post')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  _t(
                    'Đăng bài để tuyển thêm thành viên cho nhóm capstone của bạn.',
                    'Create a post to recruit more members for your capstone group.',
                  ),
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _groupIdController,
                  readOnly: isLeader && widget.membership?.groupId != null,
                  decoration: InputDecoration(
                    labelText: _t('ID nhóm', 'Group ID'),
                    helperText: _t(
                      'Thường là nhóm hiện tại của bạn.',
                      'Usually your current group ID.',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _t(
                        'Vui lòng nhập ID nhóm',
                        'Please enter group ID',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _t('Tiêu đề', 'Title'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _t(
                        'Vui lòng nhập tiêu đề',
                        'Please enter a title',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: _t('Mô tả', 'Description'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _t(
                        'Vui lòng nhập mô tả',
                        'Please enter a description',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _positionController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'Vị trí cần tuyển',
                      'Position needed (e.g. Frontend)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'Kỹ năng (phân cách bằng dấu phẩy)',
                      'Skills (comma separated)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiresAt == null
                            ? _t(
                                'Chưa chọn ngày hết hạn',
                                'No expiration date selected',
                              )
                            : _t(
                                'Hết hạn: ${_expiresAt!.toLocal().toString().split(' ').first}',
                                'Expires at: ${_expiresAt!.toLocal().toString().split(' ').first}',
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: Text(_t('Chọn ngày', 'Pick date')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_t('Đăng bài', 'Post')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
