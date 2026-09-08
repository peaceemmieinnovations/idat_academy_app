import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorReportsScreen extends StatefulWidget {
  const TutorReportsScreen({super.key});

  @override
  State<TutorReportsScreen> createState() => _TutorReportsScreenState();
}

class _TutorReportsScreenState extends State<TutorReportsScreen> {
  List<TutorReport> _reports = [];
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
    final reportsRes = await ApiService.getTutorReports();
    if (mounted && reportsRes['error'] != null) {
      setState(() {
        _error = reportsRes['error'];
        _loading = false;
      });
      return;
    }
    final coursesRes = await ApiService.getTutorCourses();
    if (!mounted) return;
    setState(() {
      _reports = ((reportsRes['data'] ?? const []) as List)
          .whereType<Map>()
          .map((m) => TutorReport.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _courses = (coursesRes['data'] ?? const [])
          .whereType<Map>()
          .map((m) => Course.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _loading = false;
    });
  }

  Course? _courseFor(TutorReport report) {
    for (final c in _courses) {
      if (c.id == report.courseId) return c;
    }
    return null;
  }

  Future<void> _create() async {
    Course? selectedCourse;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String reportType = 'class';
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
                const Text('New Report', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                if (_courses.isNotEmpty) ...[
                  DropdownButtonFormField<Course>(
                    initialValue: selectedCourse,
                    decoration: const InputDecoration(
                        labelText: 'Course (optional)', isDense: true),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('No course linked')),
                      ..._courses.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.title, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (c) => setModal(() => selectedCourse = c),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: reportType,
                  decoration:
                      const InputDecoration(labelText: 'Report Type', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'class', child: Text('Class report')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly report')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly report')),
                    DropdownMenuItem(value: 'general', child: Text('General')),
                  ],
                  onChanged: (v) => setModal(() => reportType = v ?? 'general'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                      labelText: 'Report Content',
                      alignLabelWithHint: true,
                      hintText: 'What happened in the class? Progress, challenges, notes...'),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Submit Report',
                  icon: Icons.send_rounded,
                  loading: saving,
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        contentCtrl.text.trim().length < 10) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text(
                              'Add a title and at least a few sentences of content'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    final data = <String, dynamic>{
                      'title': titleCtrl.text.trim(),
                      'content': contentCtrl.text.trim(),
                      'report_type': reportType,
                      if (selectedCourse != null)
                        'course_id': selectedCourse!.id,
                      if (ApiService.staffId != null)
                        'tutor_id': ApiService.staffId,
                    };
                    setModal(() => saving = true);
                    final res = await ApiService.createTutorReport(data);
                    if (!mounted) return;
                    setModal(() => saving = false);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['error'] == null
                          ? 'Report submitted!'
                          : res['error'].toString()),
                      backgroundColor: res['error'] == null
                          ? AppColors.success
                          : AppColors.error,
                    ));
                    if (res['error'] == null) _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(TutorReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete report?', style: AppTextStyles.h3),
        content: Text('"${report.title}" will be permanently removed.'),
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
    final res = await ApiService.deleteTutorReport(report.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] == null
            ? 'Report deleted'
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
      appBar: AppBar(title: const Text('My Reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 5, itemHeight: 120))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _reports.isEmpty
                  ? const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'No reports yet',
                      subtitle:
                          'Submit progress and class reports to keep records up to date.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _reports.length,
                        itemBuilder: (_, i) {
                          final report = _reports[i];
                          return _ReportCard(
                            report: report,
                            courseTitle: _courseFor(report)?.title,
                            onDelete: () => _delete(report),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final TutorReport report;
  final String? courseTitle;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.courseTitle,
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
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
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
              StatusChip.fromStatus(report.reportType),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.content,
              style: AppTextStyles.bodySmall,
              maxLines: 6,
              overflow: TextOverflow.ellipsis),
          if (report.createdAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_fmtDate(report.createdAt), style: AppTextStyles.bodySmall),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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

  String _fmtDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}