import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'tutor_clockin_screen.dart';

class TutorClockInTab extends StatefulWidget {
  const TutorClockInTab({super.key});

  @override
  State<TutorClockInTab> createState() => _TutorClockInTabState();
}

class _TutorClockInTabState extends State<TutorClockInTab> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  Map<int, Map<String, dynamic>> _activeSessions = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeSessions.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getTutorCourses();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        final sessions = await ClockInSession.restoreAll();
        setState(() {
          _courses = data.map((c) => Course.fromJson(c)).toList();
          _activeSessions = sessions;
          _loading = false;
        });
      }
    }
  }

  Future<void> _clockOut(int courseId, String courseTitle, DateTime clockIn, Duration elapsed) async {
    await ApiService.post('tutor/clock-out', {
      'course_id': courseId,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': DateTime.now().toIso8601String(),
      'duration_seconds': elapsed.inSeconds,
    });
    await ClockInSession.clear(courseId);
    if (mounted) {
      setState(() => _activeSessions.remove(courseId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Clocked out of "$courseTitle"'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Clock In/Out')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.secondary,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(count: 4, itemHeight: 110))
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _courses.isEmpty
                    ? const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'No courses',
                        subtitle: 'No courses assigned to you.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _courses.length,
                        itemBuilder: (_, i) {
                          final c = _courses[i];
                          final session = _activeSessions[c.id];
                          return _CourseClockCard(
                            course: c,
                            session: session,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TutorClockInScreen(
                                    courseTitle: c.title,
                                    courseId: c.id,
                                  ),
                                ),
                              );
                              if (result != null || true) _load();
                            },
                            onClockOut: session != null
                                ? () {
                                    final clockIn = DateTime.parse(session['clock_in']);
                                    final elapsed = DateTime.now().difference(clockIn);
                                    _clockOut(c.id, c.title, clockIn, elapsed);
                                  }
                                : null,
                          );
                        },
                      ),
      ),
    );
  }
}

class _CourseClockCard extends StatelessWidget {
  final Course course;
  final Map<String, dynamic>? session;
  final VoidCallback onTap;
  final VoidCallback? onClockOut;

  const _CourseClockCard({
    required this.course,
    required this.session,
    required this.onTap,
    this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = session != null;
    final DateTime? clockIn = active ? DateTime.parse(session!['clock_in']) : null;
    final Duration elapsed = active ? DateTime.now().difference(clockIn!) : Duration.zero;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.success.withValues(alpha: 0.4) : AppColors.divider,
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          if (active)
            BoxShadow(color: AppColors.success.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: active ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    active ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                    color: active ? AppColors.success : AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      if (active)
                        Text('In session · ${_formatElapsed(elapsed)}',
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600))
                      else
                        Text('Tap to clock in',
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                if (active)
                  GestureDetector(
                    onTap: onClockOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 16),
                          SizedBox(width: 4),
                          Text('Clock Out',
                              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: AppColors.secondary, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}
