import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorAssessmentsScreen extends StatefulWidget {
  const TutorAssessmentsScreen({super.key});

  @override
  State<TutorAssessmentsScreen> createState() => _TutorAssessmentsScreenState();
}

class _TutorAssessmentsScreenState extends State<TutorAssessmentsScreen> {
  List<ClassAssessment> _assessments = [];
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
    final res = await ApiService.getClassAssessments();
    if (mounted && res['error'] != null) {
      setState(() {
        _error = res['error'];
        _loading = false;
      });
      return;
    }
    final coursesRes = await ApiService.getTutorCourses();
    if (!mounted) return;
    setState(() {
      _assessments = ((res['data'] ?? const []) as List)
          .whereType<Map>()
          .map((m) => ClassAssessment.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _courses = (coursesRes['data'] ?? const [])
          .whereType<Map>()
          .map((m) => Course.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _loading = false;
    });
  }

  Course? _courseFor(ClassAssessment a) {
    for (final c in _courses) {
      if (c.id == a.courseId) return c;
    }
    return null;
  }

  Future<void> _create() async {
    Course? selectedCourse;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    String? date = DateTime.now().toIso8601String().substring(0, 10);
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
                const Text('New Assessment', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                if (_courses.isNotEmpty) ...[
                  DropdownButtonFormField<Course>(
                    initialValue: selectedCourse,
                    decoration: const InputDecoration(
                        labelText: 'Course', isDense: true),
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
                      labelText: 'Assessment Title',
                      hintText: 'e.g. Mid-term Test — Week 6'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Max Score', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.tryParse(date ?? '') ??
                                DateTime.now(),
                            firstDate: DateTime.now().subtract(
                                const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setModal(() => date =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded,
                            size: 18),
                        label: const Text('Date'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Create Assessment',
                  icon: Icons.add_rounded,
                  loading: saving,
                  onPressed: () async {
                    if (selectedCourse == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Select a course'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    final maxScore = double.tryParse(maxScoreCtrl.text.trim());
                    if (maxScore == null || maxScore <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Enter a valid max score'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    final data = <String, dynamic>{
                      'course_id': selectedCourse!.id,
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'max_score': maxScore,
                      'assessment_date': date ?? '',
                      if (ApiService.staffId != null)
                        'staff_id': ApiService.staffId,
                    };
                    setModal(() => saving = true);
                    final res =
                        await ApiService.createClassAssessment(data);
                    if (!mounted) return;
                    setModal(() => saving = false);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['error'] == null
                          ? 'Assessment created!'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Assessments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _courses.isEmpty ? null : _create,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Assessment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 5, itemHeight: 100))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _assessments.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No assessments yet',
                      subtitle:
                          'Create an assessment and record student scores for your classes.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _assessments.length,
                        itemBuilder: (_, i) {
                          final assessment = _assessments[i];
                          return _AssessmentCard(
                            assessment: assessment,
                            courseTitle: _courseFor(assessment)?.title,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssessmentScoresScreen(
                                  assessment: assessment,
                                  courseTitle: _courseFor(assessment)?.title,
                                  onSaved: _load,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final ClassAssessment assessment;
  final String? courseTitle;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.assessment,
    required this.courseTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fact_check_rounded,
                      color: AppColors.warning, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assessment.title,
                          style: AppTextStyles.h4,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (courseTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(courseTitle!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.secondary)),
                      ],
                      const SizedBox(height: 4),
                      Text(
                          'Max score: ${assessment.maxScore.toStringAsFixed(0)}'
                          '${assessment.assessmentDate != null ? ' · ${assessment.assessmentDate}' : ''}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Records student scores for one assessment. Students enrolled in the
/// assessment's course are listed and each score is sent to the API.
class AssessmentScoresScreen extends StatefulWidget {
  final ClassAssessment assessment;
  final String? courseTitle;
  final VoidCallback onSaved;

  const AssessmentScoresScreen({
    super.key,
    required this.assessment,
    required this.courseTitle,
    required this.onSaved,
  });

  @override
  State<AssessmentScoresScreen> createState() => _AssessmentScoresScreenState();
}

class _AssessmentScoresScreenState extends State<AssessmentScoresScreen> {
  List<Map<String, dynamic>> _students = [];
  final Map<int, TextEditingController> _scoreCtrls = {};
  late Map<int, double> _savedScores;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedScores = {};
    _load();
  }

  @override
  void dispose() {
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getTutorStudents();
    if (mounted && res['error'] != null) {
      setState(() {
        _error = res['error'];
        _loading = false;
      });
      return;
    }
    final students = <Map<String, dynamic>>[];
    for (final s in (res['data'] ?? const []) as List) {
      final map = Map<String, dynamic>.from(s as Map);
      students.add(map);
    }
    if (!mounted) return;
    setState(() {
      _students = students;
      for (final s in _students) {
        final id = s['id'] is int ? s['id'] : int.tryParse('${s['id'] ?? ''}');
        if (id != null) {
          _scoreCtrls[id] ??= TextEditingController();
        }
      }
      _loading = false;
    });
  }

  Future<void> _saveAll() async {
    int saved = 0;
    for (final s in _students) {
      final id = s['id'] is int ? s['id'] : int.tryParse('${s['id'] ?? ''}');
      if (id == null) continue;
      final text = _scoreCtrls[id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      double? score = double.tryParse(text);
      if (score == null || score < 0) continue;
      if (score > widget.assessment.maxScore) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Score for a student exceeds the max of ${widget.assessment.maxScore.toStringAsFixed(0)}'),
            backgroundColor: AppColors.error));
        return;
      }
      final res = await ApiService.addAssessmentScore(widget.assessment.id, {
        'student_id': id,
        'score': score,
      });
      if (res['error'] == null) {
        saved++;
        _savedScores[id] = score;
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved > 0
            ? '$saved score${saved == 1 ? '' : 's'} saved'
            : 'Enter at least one score'),
        backgroundColor: saved > 0 ? AppColors.success : AppColors.warning,
      ));
      if (saved > 0) widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Scores')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.assessment.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          if (widget.courseTitle != null) ...[
                            const SizedBox(height: 2),
                            Text(widget.courseTitle!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                          const SizedBox(height: 4),
                          Text(
                              'Max score: ${widget.assessment.maxScore.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _students.isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outline_rounded,
                              title: 'No students found',
                              subtitle:
                                  'Students enrolled in your courses will appear here.')
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _students.length,
                              itemBuilder: (_, i) {
                                final s = _students[i];
                                final id = s['id'] is int
                                    ? s['id']
                                    : int.tryParse('${s['id'] ?? ''}');
                                final name =
                                    '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                                        .trim();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          name.isEmpty
                                              ? '?'
                                              : name[0].toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            Text(
                                              _savedScores[id] != null
                                                  ? 'Saved: ${_savedScores[id]}'
                                                  : s['email'] ?? '',
                                              style: AppTextStyles.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 90,
                                        child: TextField(
                                          controller:
                                              id != null ? _scoreCtrls[id] : null,
                                          keyboardType:
                                              TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Score',
                                            contentPadding: EdgeInsets
                                                .symmetric(vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _students.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _saveAll,
              backgroundColor: AppColors.success,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Save Scores',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }
}