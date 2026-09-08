// ─── Results Screen ───────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'student_certificates_screen.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  List<Assignment> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentResults();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _results = data.map((a) => Assignment.fromJson(a)).toList();
          _loading = false;
        });
      }
    }
  }

  double get _average {
    // Average of normalized percentages so a small max score can never distort
    // the overall result, and a max score of zero cannot produce NaN/Infinity.
    final graded = _results
        .where((r) => r.score != null && r.maxScore > 0)
        .toList();
    if (graded.isEmpty) return 0;
    return graded.fold(
            0.0,
            (sum, r) => sum + (r.score! / r.maxScore * 100)) /
        graded.length;
  }

  String get _grade {
    final avg = _average;
    if (avg >= 70) return 'A';
    if (avg >= 60) return 'B';
    if (avg >= 50) return 'C';
    if (avg >= 45) return 'D';
    return 'F';
  }

  // Courses are grouped by course_title so the bar chart shows how the
  // student is performing per course.
  List<_CourseAverage> get _courseAverages {
    final byCourse = <String, List<Assignment>>{};
    for (final r in _results) {
      final key = (r.courseTitle?.trim().isNotEmpty ?? false)
          ? r.courseTitle!.trim()
          : 'Other';
      byCourse.putIfAbsent(key, () => []).add(r);
    }
    final list = byCourse.entries.map((e) {
      final graded =
          e.value.where((r) => r.score != null && r.maxScore > 0).toList();
      if (graded.isEmpty) return _CourseAverage(e.key, null);
      final avg = graded.fold(0.0, (sum, r) => sum + (r.score! / r.maxScore * 100)) /
          graded.length;
      return _CourseAverage(e.key, avg);
    }).toList();
    list.sort((a, b) => (b.avg ?? -1).compareTo(a.avg ?? -1));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        actions: [
          IconButton(
            tooltip: 'My Certificates',
            icon: const Icon(Icons.workspace_premium_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentCertificatesScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList(count: 5))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _results.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'No results yet',
                      subtitle: 'Graded assignments will appear here.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        // Summary card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Overall Average',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('${_average.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900)),
                                        const SizedBox(width: 8),
                                        Text('Grade $_grade',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${_results.where((r) => r.score != null).length} assignments graded',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    color: AppColors.accent, size: 36),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_courseAverages.isNotEmpty) ...[
                          const Text('Performance by Course',
                              style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          const Text(
                            'Average percentage across your graded assignments per course.',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: _courseAverages
                                  .map((ca) => _CourseBar(average: ca))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        const Text('Graded Assignments',
                            style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        ..._results.map((r) => _ResultTile(result: r)),
                      ],
                    ),
    );
  }
}

class _CourseAverage {
  final String courseTitle;
  final double? avg;
  const _CourseAverage(this.courseTitle, this.avg);
}

class _CourseBar extends StatelessWidget {
  final _CourseAverage average;
  const _CourseBar({required this.average});

  @override
  Widget build(BuildContext context) {
    final avg = average.avg;
    final value = avg?.clamp(0.0, 100.0) ?? 0.0;
    final color = avg == null
        ? AppColors.textGrey
        : value >= 70
            ? AppColors.success
            : value >= 50
                ? AppColors.warning
                : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(average.courseTitle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(avg == null ? 'No grade' : '${avg.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Assignment result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    // Guard against a missing/zero max score so the indicator never receives
    // an invalid (NaN or Infinity) value.
    final pct = (result.score != null && result.maxScore > 0)
        ? (result.score! / result.maxScore * 100).clamp(0.0, 100.0)
        : null;
    final color = pct == null
        ? AppColors.textGrey
        : pct >= 70
            ? AppColors.success
            : pct >= 50
                ? AppColors.warning
                : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                result.score != null
                    ? '${result.score!.toStringAsFixed(0)}'
                    : '-',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title,
                    style: AppTextStyles.h4.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (result.courseTitle != null)
                  Text(result.courseTitle!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.secondary)),
                if (pct != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (result.score != null) ...[
            const SizedBox(width: 8),
            Text('${result.maxScore.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
