import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'tutor_clockin_screen.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  TutorDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getTutorDashboard();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        setState(() {
          _dashboard = TutorDashboard.fromJson(res);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final tutor = auth.tutor;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.secondary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF3A10C0)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tutor Portal',
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      tutor != null
                                          ? 'Hello, ${tutor.firstName}!'
                                          : 'Hello!',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  (tutor?.firstName ?? 'T')[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text('Dashboard'),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: ErrorState(message: _error!, onRetry: _load),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        StatCard(
                          label: 'My Students',
                          value: '${_dashboard?.totalStudents ?? 0}',
                          icon: Icons.people_rounded,
                          color: AppColors.secondary,
                        ),
                        StatCard(
                          label: 'My Courses',
                          value: '${_dashboard?.totalCourses ?? 0}',
                          icon: Icons.menu_book_rounded,
                          color: AppColors.success,
                        ),
                        StatCard(
                          label: 'Pending Reviews',
                          value: '${_dashboard?.pendingSubmissions ?? 0}',
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.warning,
                        ),
                        StatCard(
                          label: 'Total Lessons',
                          value: '${_dashboard?.totalLessons ?? 0}',
                          icon: Icons.video_library_rounded,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── Clock-In Card ────────────────────────────────────
                    const _AiTutorBanner(),
                    const SizedBox(height: 20),
                    if (_dashboard?.courses.isNotEmpty == true)
                      Column(
                        children: [
                          const SectionHeader(title: 'Quick Actions'),
                          const SizedBox(height: 10),
                          ..._dashboard!.courses.take(3).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TutorClockInCard(
                              courseTitle: c.title,
                              courseId: c.id,
                            ),
                          )),
                        ],
                      ),
                    const SizedBox(height: 28),
                    if (_dashboard?.courses.isNotEmpty == true) ...[
                      const SectionHeader(title: 'My Courses'),
                      const SizedBox(height: 12),
                      ..._dashboard!.courses
                          .map((c) => CourseCard(course: c))
                          .toList(),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiTutorBanner extends StatelessWidget {
  const _AiTutorBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI lesson tools',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Upload lessons to generate student summaries and quiz practice.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}
