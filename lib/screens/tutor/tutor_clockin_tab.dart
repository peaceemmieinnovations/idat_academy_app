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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getTutorCourses();
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
      appBar: AppBar(title: const Text('Course Clock In/Out')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.secondary,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(count: 4, itemHeight: 90))
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
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TutorClockInCard(
                            courseTitle: _courses[i].title,
                            courseId: _courses[i].id,
                          ),
                        ),
                      ),
      ),
    );
  }
}
