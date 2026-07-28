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
    final graded = _results.where((r) => r.score != null).toList();
    if (graded.isEmpty) return 0;
    return graded.fold(0.0, (sum, r) => sum + r.score!) / graded.length;
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
                                    Text('${_average.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900)),
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
                        const SizedBox(height: 20),
                        ..._results.map((r) => _ResultTile(result: r)),
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
    final pct = result.score != null
        ? (result.score! / result.maxScore * 100)
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
