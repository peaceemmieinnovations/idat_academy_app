import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'student_lessons_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  final Set<int> _registering = {};

  List<Course> get _registeredCourses =>
      _courses.where((c) => c.progress != null).toList();

  List<Course> get _availableCourses =>
      _courses.where((c) => c.progress == null).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentCourses();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _courses = data.map((c) => Course.fromJson(c)).toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleRegister(Course course) async {
    setState(() => _registering.add(course.id));
    final res = await ApiService.registerCourse(course.id);
    if (mounted) {
      setState(() => _registering.remove(course.id));
      if (res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.secondary,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(count: 4, itemHeight: 200),
              )
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _courses.isEmpty
                    ? const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'No courses',
                        subtitle: 'No courses available at the moment.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          if (_registeredCourses.isNotEmpty) ...[
                            const SectionHeader(title: 'My Courses'),
                            const SizedBox(height: 12),
                            ..._registeredCourses.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: CourseCard(
                                course: c,
                                showProgress: true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentLessonsScreen(course: c),
                                  ),
                                ),
                              ),
                            )),
                            const SizedBox(height: 28),
                          ],
                          if (_availableCourses.isNotEmpty) ...[
                            const SectionHeader(title: 'Available Courses'),
                            const SizedBox(height: 12),
                            ..._availableCourses.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AvailableCourseCard(
                                course: c,
                                loading: _registering.contains(c.id),
                                onRegister: () => _handleRegister(c),
                              ),
                            )),
                          ],
                        ],
                      ),
      ),
    );
  }
}

class _AvailableCourseCard extends StatelessWidget {
  final Course course;
  final bool loading;
  final VoidCallback onRegister;
  const _AvailableCourseCard({
    required this.course,
    required this.loading,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16, bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  Positioned(
                    right: 16, bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.learningMode.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: AppTextStyles.h4, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(course.duration ?? 'Flexible', style: AppTextStyles.bodySmall),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : onRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Register Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
