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
                        title: 'No courses enrolled',
                        subtitle: 'You are not enrolled in any courses yet.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _courses.length,
                        itemBuilder: (_, i) => CourseCard(
                          course: _courses[i],
                          showProgress: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentLessonsScreen(
                                  course: _courses[i]),
                            ),
                          ),
                        ),
                      ),
      ),
    );
  }
}
