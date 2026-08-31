import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'ai_learning_hub_screen.dart';

class StudentLessonsScreen extends StatefulWidget {
  final Course course;
  const StudentLessonsScreen({super.key, required this.course});

  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  List<Lesson> _lessons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentLessons(widget.course.id);
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _lessons = data.map((l) => Lesson.fromJson(l)).toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openLesson(Lesson lesson) async {
    final url = ApiService.fileUrl(lesson.filePath);
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This lesson has no downloadable file yet.'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot open file'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          // Course header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.course.progress != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Course Progress',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13)),
                      Text('${widget.course.progress?.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (widget.course.progress ?? 0) / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                      minHeight: 8,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: widget.course.duration ?? 'Flexible'),
                    const SizedBox(width: 10),
                    _InfoChip(
                        icon: Icons.laptop_mac_rounded,
                        label: widget.course.learningMode),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.secondary,
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: ShimmerList(count: 5, itemHeight: 80),
                    )
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _load)
                      : _lessons.isEmpty
                          ? const EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No lessons yet',
                              subtitle:
                                  'Your tutor will upload lessons soon.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: _lessons.length,
                              itemBuilder: (_, i) =>
                                  _LessonTile(
                                    lesson: _lessons[i],
                                    index: i + 1,
                                    onTap: () => _openLesson(_lessons[i]),
                                    onAskAi: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiLearningHubScreen(
                                      lessonId: _lessons[i].id,
                                      lessonTitle: _lessons[i].title,
                                      lessonTopic: widget.course.title,
                                      lessonContent: _lessons[i].description,
                                    ))),
                                  ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAskAi;
  const _LessonTile(
      {required this.lesson, required this.index, required this.onTap, required this.onAskAi});

  @override
  Widget build(BuildContext context) {
    final iconData = lesson.fileType == 'ppt'
        ? Icons.slideshow_rounded
        : lesson.fileType == 'notes'
            ? Icons.notes_rounded
            : Icons.picture_as_pdf_rounded;

    final color = lesson.fileType == 'ppt'
        ? AppColors.warning
        : lesson.fileType == 'notes'
            ? AppColors.success
            : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(iconData, color: color, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                      style: AppTextStyles.h4.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (lesson.description != null) ...[
                    const SizedBox(height: 3),
                    Text(lesson.description!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lesson.fileTypeLabel,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: onAskAi, tooltip: 'Ask AI about this lesson', icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 22)),
            const SizedBox(width: 2),
            Icon(Icons.download_rounded, color: AppColors.secondary, size: 22),
          ],
        ),
      ),
    );
  }
}
