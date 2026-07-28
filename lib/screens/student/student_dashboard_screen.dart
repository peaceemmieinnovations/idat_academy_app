import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../student/student_courses_screen.dart';
import '../student/student_notifications_screen.dart';
import 'ai_learning_hub_screen.dart';
import 'voice_assignment_screen.dart';
import 'gamification_hub_screen.dart';
import '../../services/gamification_service.dart';
import 'student_lessons_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  StudentDashboard? _dashboard;
  List<Course> _allCourses = [];
  bool _loading = true;
  bool _loadingCourses = false;
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
        _loadAllCourses();
      }
    }
  }

  Future<void> _loadAllCourses() async {
    setState(() => _loadingCourses = true);
    final res = await ApiService.getStudentCourses();
    if (mounted) {
      final data = res['data'] as List? ?? [];
      setState(() {
        _allCourses = data.map((c) => Course.fromJson(c)).toList();
        _loadingCourses = false;
      });
    }
  }

  Map<String, List<Course>> get _groupedCourses {
    final map = <String, List<Course>>{};
    for (final c in _allCourses) {
      map.putIfAbsent(c.learningMode, () => []).add(c);
    }
    return map;
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
                      colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
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
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
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
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
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
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                      childAspectRatio: 1.05,
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
                        ValueListenableBuilder<GamificationState>(
                          valueListenable: GamificationService.state,
                          builder: (_, game, __) => StatCard(
                            label: 'Learning Streak', value: '${game.streak} days',
                            icon: Icons.local_fire_department_rounded, color: AppColors.warning,
                          ),
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

                    ValueListenableBuilder<GamificationState>(
                      valueListenable: GamificationService.state,
                      builder: (_, game, __) => _LearningMomentum(
                        game: game,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GamificationHubScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _AiBanner(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AiLearningHubScreen()),
                      ),
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
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Studio',
                          color: const Color(0xFF7C3AED),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiLearningHubScreen())),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.mic_rounded,
                          label: 'Voice Draft',
                          color: AppColors.success,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceAssignmentScreen())),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.emoji_events_rounded,
                          label: 'My Rewards',
                          color: AppColors.accent,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationHubScreen())),
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
                    const SizedBox(height: 28),

                    // Categorized courses
                    if (_allCourses.isNotEmpty) ...[
                      SectionHeader(title: 'All Courses'),
                      const SizedBox(height: 12),
                    ],
                    if (_loadingCourses)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                      )
                    else ...[
                      ..._buildCategorySection('hybrid', 'Hybrid Courses',
                          'Blended learning — online & in-person'),
                      ..._buildCategorySection('online', 'Online Courses',
                          'Fully virtual — learn from anywhere'),
                      ..._buildCategorySection('physical', 'Physical Courses',
                          'On-campus classroom sessions'),
                    ],
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
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Widget> _buildCategorySection(String mode, String title, String subtitle) {
    final courses = _groupedCourses[mode] ?? [];
    if (courses.isEmpty) return [];

    return [
      SectionHeader(
        title: title,
        actionLabel: 'View All',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentCoursesScreen()),
        ),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 10),
      ...courses.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _CompactCourseCard(course: c),
      )),
      const SizedBox(height: 16),
    ];
  }
}

class _CompactCourseCard extends StatelessWidget {
  final Course course;
  const _CompactCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'brain': Icons.psychology_rounded,
      'shield': Icons.shield_rounded,
      'code': Icons.code_rounded,
      'marketing': Icons.trending_up_rounded,
      'chart': Icons.bar_chart_rounded,
    };
    final icon = iconMap[course.icon] ?? Icons.menu_book_rounded;

    Color modeColor;
    switch (course.learningMode) {
      case 'hybrid':
        modeColor = const Color(0xFF8B5CF6);
      case 'online':
        modeColor = const Color(0xFF06B6D4);
      default:
        modeColor = const Color(0xFF10B981);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentLessonsScreen(course: course)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: modeColor, size: 24),
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
                      Text(
                        course.description ?? 'No description',
                        style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.learningMode.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: modeColor),
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

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open AI Learning Studio',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Learning Studio', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Smart summaries, quiz practice & course help.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ),
        ]),
      ),
    ),
  );
}

class _LearningMomentum extends StatelessWidget {
  final GamificationState game;
  final VoidCallback onTap;

  const _LearningMomentum({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = (game.xp / game.nextLevelXp).clamp(0.0, 1.0);
    final remaining = (game.nextLevelXp - game.xp).clamp(0, game.nextLevelXp);
    return Semantics(
      button: true,
      label: 'Open learning journey. ${game.xp} experience points.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.bolt_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${game.level} learner',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        Text('${game.xp} XP earned · ${game.badges.length} badges',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 8),
              Text('$remaining XP to your next level',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.04),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
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
