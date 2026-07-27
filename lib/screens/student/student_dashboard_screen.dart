import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../student/student_courses_screen.dart';
import '../student/student_notifications_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  StudentDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentDashboard();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        setState(() {
          _dashboard = StudentDashboard.fromJson(res);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final student = auth.student;
    final greeting = _greeting();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.secondary,
        child: CustomScrollView(
          slivers: [
            // Gradient app bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
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
                                    Text(greeting,
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      student?.firstName ?? 'Student',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const StudentNotificationsScreen()),
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      (student?.firstName ?? 'S')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
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
                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        StatCard(
                          label: 'Enrolled Courses',
                          value: '${_dashboard?.enrolledCourses ?? 0}',
                          icon: Icons.menu_book_rounded,
                          color: AppColors.secondary,
                        ),
                        StatCard(
                          label: 'Completed',
                          value: '${_dashboard?.completedCourses ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                        StatCard(
                          label: 'Pending Tasks',
                          value: '${_dashboard?.pendingAssignments ?? 0}',
                          icon: Icons.assignment_outlined,
                          color: AppColors.warning,
                        ),
                        StatCard(
                          label: 'Certificates',
                          value: '${_dashboard?.certificates ?? 0}',
                          icon: Icons.workspace_premium_rounded,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Quick actions
                    SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'My Courses',
                          color: AppColors.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StudentCoursesScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.assignment_rounded,
                          label: 'Assignments',
                          color: AppColors.warning,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Certificates',
                          color: AppColors.success,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Results',
                          color: AppColors.accent,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Recent courses
                    if (_dashboard?.recentCourses.isNotEmpty == true) ...[
                      SectionHeader(
                        title: 'Continue Learning',
                        actionLabel: 'See All',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StudentCoursesScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._dashboard!.recentCourses
                          .map((c) => CourseCard(
                                course: c,
                                showProgress: true,
                                onTap: () {},
                              ))
                          .toList(),
                    ] else
                      const EmptyState(
                        icon: Icons.school_rounded,
                        title: 'No courses yet',
                        subtitle: 'Your enrolled courses will appear here',
                      ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌅';
    if (h < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
