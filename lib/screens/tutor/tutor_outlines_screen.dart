import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorOutlinesScreen extends StatefulWidget {
  const TutorOutlinesScreen({super.key});

  @override
  State<TutorOutlinesScreen> createState() => _TutorOutlinesScreenState();
}

class _TutorOutlinesScreenState extends State<TutorOutlinesScreen> {
  List<CourseOutline> _outlines = [];
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final outlinesRes = await ApiService.getCourseOutlines();
    if (mounted && outlinesRes['error'] != null) {
      setState(() {
        _error = outlinesRes['error'];
        _loading = false;
      });
      return;
    }
    final coursesRes = await ApiService.getTutorCourses();
    if (!mounted) return;
    setState(() {
      _outlines = ((outlinesRes['data'] ?? const []) as List)
          .whereType<Map>()
          .map((m) => CourseOutline.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _courses = (coursesRes['data'] ?? const [])
          .whereType<Map>()
          .map((m) => Course.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _loading = false;
    });
  }

  Course? _courseFor(CourseOutline outline) {
    for (final c in _courses) {
      if (c.id == outline.courseId) return c;
    }
    return null;
  }

  Future<void> _createOrEdit({CourseOutline? outline}) async {
    final course = outline != null ? _courseFor(outline) : null;
    await _showOutlineSheet(
      outline: outline,
      initialCourse: course,
    );
    _load();
  }

  Future<void> _showOutlineSheet({required CourseOutline? outline, Course? initialCourse}) async {
    Course? selectedCourse = initialCourse;
    final titleCtrl = TextEditingController(text: outline?.title ?? '');
    final descCtrl =
        TextEditingController(text: outline?.description ?? '');
    final objectivesCtrl =
        TextEditingController(text: outline?.objectives ?? '');
    final contentCtrl =
        TextEditingController(text: outline?.outlineContent ?? '');
    String status = outline?.status ?? 'draft';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outline == null ? 'New Course Outline' : 'Edit Outline',
                    style: AppTextStyles.h3),
                const SizedBox(height: 20),
                if (_courses.isNotEmpty) ...[
                  DropdownButtonFormField<Course>(
                    initialValue: selectedCourse,
                    decoration:
                        const InputDecoration(labelText: 'Course', isDense: true),
                    items: _courses
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.title, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (c) => setModal(() => selectedCourse = c),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Introduction to Neural Networks'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objectivesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Learning Objectives',
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                      labelText: 'Outline Content',
                      alignLabelWithHint: true,
                      hintText: 'Key points, activities and take-home tasks'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Published')),
                  ],
                  onChanged: (v) => setModal(() => status = v ?? 'draft'),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: outline == null ? 'Create Outline' : 'Save Changes',
                  icon: Icons.save_rounded,
                  loading: saving,
                  onPressed: () async {
                    if (selectedCourse == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Select a course'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    final data = <String, dynamic>{
                      'course_id': selectedCourse!.id,
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'objectives': objectivesCtrl.text.trim(),
                      'outline_content': contentCtrl.text.trim(),
                      'status': status,
                      if (ApiService.staffId != null)
                        'tutor_id': ApiService.staffId,
                    };
                    setModal(() => saving = true);
                    final res = outline == null
                        ? await ApiService.createCourseOutline(data)
                        : await ApiService.updateCourseOutline(outline.id, data);
                    if (!mounted) return;
                    setModal(() => saving = false);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['error'] == null
                          ? (outline == null
                              ? 'Outline created!'
                              : 'Outline updated!')
                          : res['error'].toString()),
                      backgroundColor: res['error'] == null
                          ? AppColors.success
                          : AppColors.error,
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(CourseOutline outline) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete outline?', style: AppTextStyles.h3),
        content: Text('"${outline.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await ApiService.deleteCourseOutline(outline.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] == null
            ? 'Outline deleted'
            : res['error'].toString()),
        backgroundColor:
            res['error'] == null ? AppColors.success : AppColors.error,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Outlines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _courses.isEmpty ? null : () => _createOrEdit(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Outline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 5, itemHeight: 120))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _outlines.isEmpty
                  ? const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No outlines yet',
                      subtitle:
                          'Create your first lesson outline to prepare each class session.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _outlines.length,
                        itemBuilder: (_, i) {
                          final outline = _outlines[i];
                          final course = _courseFor(outline);
                          return _OutlineCard(
                            outline: outline,
                            courseTitle: course?.title,
                            onEdit: () => _createOrEdit(outline: outline),
                            onDelete: () => _delete(outline),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _OutlineCard extends StatelessWidget {
  final CourseOutline outline;
  final String? courseTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OutlineCard({
    required this.outline,
    required this.courseTitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(outline.title,
                        style: AppTextStyles.h4,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (courseTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(courseTitle!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.secondary)),
                    ],
                  ],
                ),
              ),
              StatusChip.fromStatus(outline.status),
            ],
          ),
          if (outline.objectives?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Objectives',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(outline.objectives!,
                style: AppTextStyles.bodySmall, maxLines: 3),
          ],
          if (outline.outlineContent?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(outline.outlineContent!,
                style: AppTextStyles.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}