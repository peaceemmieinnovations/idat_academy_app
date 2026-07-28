import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorAssignmentsScreen extends StatefulWidget {
  const TutorAssignmentsScreen({super.key});

  @override
  State<TutorAssignmentsScreen> createState() =>
      _TutorAssignmentsScreenState();
}

class _TutorAssignmentsScreenState extends State<TutorAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  List<Assignment> _assignments = [];
  bool _loading = true;
  String? _error;
  late TabController _tabs;
  List<Course> _courses = [];

  final List<Map<String, dynamic>> _adminTasks = [
    {
      'title': 'Submit Lesson Plans',
      'description': 'Upload lesson plans for all courses for the upcoming term.',
      'deadline': '2026-08-15',
      'priority': 'high',
    },
    {
      'title': 'Student Progress Report',
      'description': 'Submit progress report for all students in your courses.',
      'deadline': '2026-08-30',
      'priority': 'medium',
    },
    {
      'title': 'Course Material Review',
      'description': 'Review and update course materials for the new curriculum.',
      'deadline': '2026-09-10',
      'priority': 'low',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([
      ApiService.getTutorAssignments(),
      ApiService.getTutorCourses(),
    ]);
    if (mounted) {
      if (results[0]['error'] != null) {
        setState(() { _error = results[0]['error']; _loading = false; });
        return;
      }
      final assignData = results[0]['data'] as List? ?? [];
      final courseData = results[1]['data'] as List? ?? [];
      setState(() {
        _assignments = assignData.map((a) => Assignment.fromJson(a)).toList();
        _courses = courseData.map((c) => Course.fromJson(c)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _createAssignment() async {
    Course? selectedCourse;
    final titleCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    DateTime? dueDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Create Assignment', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                DropdownButtonFormField<Course>(
                  initialValue: selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  items: _courses
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.title,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (c) => setModal(() => selectedCourse = c),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: instrCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: maxScoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Score',
                    prefixIcon: Icon(Icons.score_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.secondary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: dueDate != null
                                ? AppColors.secondary
                                : AppColors.textGrey,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(
                          dueDate != null
                              ? 'Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}'
                              : 'Set Due Date (optional)',
                          style: TextStyle(
                            color: dueDate != null
                                ? AppColors.dark
                                : AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Create Assignment',
                  icon: Icons.add_task_rounded,
                  onPressed: () async {
                    if (selectedCourse == null ||
                        titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Course and title are required'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    final res = await ApiService.post('tutor/assignments', {
                      'course_id': selectedCourse!.id,
                      'title': titleCtrl.text.trim(),
                      'instructions': instrCtrl.text.trim(),
                      'max_score': double.tryParse(maxScoreCtrl.text) ?? 100,
                      'accepted_file_types': 'pdf,doc,docx,zip',
                      if (dueDate != null)
                        'due_date': dueDate!.toIso8601String(),
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      if (res['error'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Assignment created!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res['error']),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'Assignments (${_assignments.length})'),
            const Tab(text: 'Pending Reviews'),
            const Tab(text: 'From Admin'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAssignment,
        backgroundColor: AppColors.secondary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Assignment',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 4, itemHeight: 140))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    // All assignments
                    _assignments.isEmpty
                        ? const EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No assignments yet',
                            subtitle: 'Create your first assignment below.',
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            itemCount: _assignments.length,
                            itemBuilder: (_, i) => _AssignmentCard(
                              assignment: _assignments[i],
                              onViewSubmissions: () =>
                                  _viewSubmissions(_assignments[i]),
                            ),
                          ),
                    // Pending reviews (submitted but ungraded)
                    _PendingReviewsList(assignments: _assignments),
                    // Tasks from admin
                    _adminTasks.isEmpty
                        ? const EmptyState(
                            icon: Icons.task_rounded,
                            title: 'No tasks from admin',
                            subtitle: 'Admin tasks will appear here.',
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            itemCount: _adminTasks.length,
                            itemBuilder: (_, i) => _AdminTaskCard(
                              task: _adminTasks[i],
                            ),
                          ),
                  ],
                ),
    );
  }

  void _viewSubmissions(Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionsScreen(assignment: assignment),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onViewSubmissions;

  const _AssignmentCard(
      {required this.assignment, required this.onViewSubmissions});

  @override
  Widget build(BuildContext context) {
    final overdue = assignment.dueDate != null &&
        DateTime.tryParse(assignment.dueDate!)
                ?.isBefore(DateTime.now()) ==
            true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top colored strip
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assignment.title,
                              style: AppTextStyles.h4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (assignment.courseTitle != null) ...[
                            const SizedBox(height: 4),
                            Text(assignment.courseTitle!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.secondary)),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '/${assignment.maxScore.toStringAsFixed(0)} pts',
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (assignment.dueDate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: overdue ? AppColors.error : AppColors.textGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        overdue ? 'Overdue' : 'Due: ',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              overdue ? AppColors.error : AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!overdue)
                        Text(
                          _fmtDate(assignment.dueDate!),
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewSubmissions,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('View Submissions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _PendingReviewsList extends StatefulWidget {
  final List<Assignment> assignments;
  const _PendingReviewsList({required this.assignments});

  @override
  State<_PendingReviewsList> createState() => _PendingReviewsListState();
}

class _PendingReviewsListState extends State<_PendingReviewsList> {
  @override
  Widget build(BuildContext context) {
    if (widget.assignments.isEmpty) {
      return const EmptyState(
        icon: Icons.done_all_rounded,
        title: 'All caught up!',
        subtitle: 'No pending submissions to review.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: widget.assignments.length,
      itemBuilder: (_, i) => _QuickReviewTile(
        assignment: widget.assignments[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SubmissionsScreen(assignment: widget.assignments[i]),
          ),
        ),
      ),
    );
  }
}

class _QuickReviewTile extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;
  const _QuickReviewTile({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.title,
                      style: AppTextStyles.h4.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (assignment.courseTitle != null)
                    Text(assignment.courseTitle!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// ─── Submissions Screen ───────────────────────────────────────────────────────

class SubmissionsScreen extends StatefulWidget {
  final Assignment assignment;
  const SubmissionsScreen({super.key, required this.assignment});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  List<Submission> _submissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res =
        await ApiService.getTutorSubmissions(widget.assignment.id);
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _submissions = data.map((s) => Submission.fromJson(s)).toList();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submissions', style: TextStyle(fontSize: 16)),
            Text(
              widget.assignment.title,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 5, itemHeight: 100))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _submissions.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No submissions yet',
                      subtitle:
                          'Students have not submitted this assignment yet.',
                    )
                  : Column(
                      children: [
                        // Summary banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.white,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryPill(
                                label: 'Total',
                                value: '${_submissions.length}',
                                color: AppColors.secondary,
                              ),
                              _SummaryPill(
                                label: 'Graded',
                                value: '${_submissions.where((s) => s.score != null).length}',
                                color: AppColors.success,
                              ),
                              _SummaryPill(
                                label: 'Pending',
                                value: '${_submissions.where((s) => s.score == null).length}',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _submissions.length,
                            itemBuilder: (_, i) => _SubmissionCard(
                              submission: _submissions[i],
                              maxScore: widget.assignment.maxScore,
                              onGrade: () => _gradeSheet(_submissions[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _gradeSheet(Submission sub) {
    final scoreCtrl = TextEditingController(
        text: sub.score?.toStringAsFixed(0) ?? '');
    final feedbackCtrl = TextEditingController(text: sub.feedback ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Grade: ${sub.studentName}', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            if (sub.filePath != null) ...[
              GestureDetector(
                onTap: () async {
                  final url =
                      '${ApiService.baseUrl.replaceAll('/api', '')}/${sub.filePath}';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.download_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 10),
                      Text('View Submitted File',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (sub.typedResponse != null && sub.typedResponse!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Response',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(sub.typedResponse!, style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Score (max ${widget.assignment.maxScore.toStringAsFixed(0)})',
                prefixIcon: const Icon(Icons.score_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                prefixIcon: Icon(Icons.feedback_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Save Grade',
              icon: Icons.check_circle_rounded,
              onPressed: () async {
                final score = double.tryParse(scoreCtrl.text);
                if (score == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enter a valid score'),
                      backgroundColor: AppColors.error));
                  return;
                }
                final res = await ApiService.gradeSubmission(sub.id, {
                  'score': score,
                  'feedback': feedbackCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res['error'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Grade saved!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _load();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res['error']),
                        backgroundColor: AppColors.error));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Submission submission;
  final double maxScore;
  final VoidCallback onGrade;

  const _SubmissionCard(
      {required this.submission,
      required this.maxScore,
      required this.onGrade});

  @override
  Widget build(BuildContext context) {
    final graded = submission.score != null;
    final pct = graded ? (submission.score! / maxScore * 100) : 0.0;
    final scoreColor = pct >= 70
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: graded
              ? scoreColor.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                child: Text(
                  submission.studentName[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submission.studentName,
                        style: AppTextStyles.h4.copyWith(fontSize: 14)),
                    Text(
                      'Submitted ${_fmtDate(submission.submittedAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (graded)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${submission.score!.toStringAsFixed(0)}/${ maxScore.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
            ],
          ),
          if (graded && submission.score != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: AppColors.lightGrey,
                valueColor: AlwaysStoppedAnimation(scoreColor),
                minHeight: 5,
              ),
            ),
          ],
          if (submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(submission.feedback!,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGrade,
              icon: Icon(
                  graded ? Icons.edit_rounded : Icons.grade_rounded,
                  size: 18),
              label: Text(graded ? 'Update Grade' : 'Grade Submission'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    graded ? AppColors.dark : AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d · h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

class _AdminTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _AdminTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final deadline = task['deadline'] as String? ?? '';
    final priority = task['priority'] as String? ?? 'medium';
    final title = task['title'] as String? ?? '';
    final description = task['description'] as String? ?? '';

    Color priorityColor;
    IconData priorityIcon;
    switch (priority) {
      case 'high':
        priorityColor = AppColors.error;
        priorityIcon = Icons.priority_high_rounded;
      case 'medium':
        priorityColor = AppColors.warning;
        priorityIcon = Icons.remove_red_eye_rounded;
      default:
        priorityColor = AppColors.success;
        priorityIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(priorityIcon, color: priorityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h4),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(priority.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor)),
                        ),
                        if (deadline.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(deadline, style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, style: AppTextStyles.body.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
