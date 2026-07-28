// ─── Tutor Lessons Screen ────────────────────────────────────────────────────
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'tutor_student_profile_screen.dart';

class TutorLessonsScreen extends StatefulWidget {
  const TutorLessonsScreen({super.key});

  @override
  State<TutorLessonsScreen> createState() => _TutorLessonsScreenState();
}

class _TutorLessonsScreenState extends State<TutorLessonsScreen> {
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Lesson> _lessons = [];
  bool _loadingCourses = true;
  bool _loadingLessons = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    final res = await ApiService.getTutorCourses();
    if (mounted) {
      final data = res['data'] as List? ?? [];
      setState(() {
        _courses = data.map((c) => Course.fromJson(c)).toList();
        _loadingCourses = false;
        if (_courses.isNotEmpty) {
          _selectedCourse = _courses[0];
          _loadLessons();
        }
      });
    }
  }

  Future<void> _loadLessons() async {
    if (_selectedCourse == null) return;
    setState(() => _loadingLessons = true);
    final res = await ApiService.getTutorLessons(_selectedCourse!.id);
    if (mounted) {
      final data = res['data'] as List? ?? [];
      setState(() {
        _lessons = data.map((l) => Lesson.fromJson(l)).toList();
        _loadingLessons = false;
      });
    }
  }

  Future<void> _uploadLesson() async {
    if (_selectedCourse == null) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String fileType = 'pdf';
    File? file;
    String? fileName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Lesson', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Lesson Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: fileType,
                  decoration: const InputDecoration(labelText: 'File Type'),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'ppt', child: Text('Slides (PPT)')),
                    DropdownMenuItem(value: 'notes', child: Text('Notes')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setModal(() => fileType = v!),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      setModal(() {
                        file = File(result.files.single.path!);
                        fileName = result.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: file != null
                              ? AppColors.success
                              : AppColors.lightGrey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            file != null
                                ? Icons.check_circle_rounded
                                : Icons.attach_file_rounded,
                            color: file != null
                                ? AppColors.success
                                : AppColors.textGrey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName ?? 'Attach file',
                            style: TextStyle(
                                color: file != null
                                    ? AppColors.success
                                    : AppColors.textGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Upload Lesson',
                  icon: Icons.upload_rounded,
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Title is required'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    Map<String, dynamic> res;
                    if (file != null) {
                      res = await ApiService.uploadFile(
                        'tutor/lessons',
                        file!,
                        {
                          'course_id': _selectedCourse!.id.toString(),
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'file_type': fileType,
                        },
                      );
                    } else {
                      res = await ApiService.post('tutor/lessons', {
                        'course_id': _selectedCourse!.id,
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'file_type': fileType,
                      });
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      if (res['error'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Lesson uploaded!'),
                              backgroundColor: AppColors.success));
                        _loadLessons();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['error']),
                            backgroundColor: AppColors.error));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadLesson,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.upload_rounded, color: Colors.white),
        label: const Text('Upload Lesson',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loadingCourses
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : Column(
              children: [
                if (_courses.isNotEmpty)
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: DropdownButtonFormField<Course>(
                      initialValue: _selectedCourse,
                      decoration: const InputDecoration(
                          labelText: 'Select Course', isDense: true),
                      items: _courses
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.title, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (c) {
                        setState(() => _selectedCourse = c);
                        _loadLessons();
                      },
                    ),
                  ),
                Expanded(
                  child: _loadingLessons
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: ShimmerList(count: 5, itemHeight: 80))
                      : _lessons.isEmpty
                          ? const EmptyState(
                              icon: Icons.upload_file_rounded,
                              title: 'No lessons uploaded',
                              subtitle: 'Tap the button below to upload your first lesson.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                              itemCount: _lessons.length,
                              itemBuilder: (_, i) {
                                final l = _lessons[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: AppColors.secondary,
                                        size: 22),
                                  ),
                                  title: Text(l.title,
                                      style: AppTextStyles.h4
                                          .copyWith(fontSize: 14)),
                                  subtitle: Text(l.fileTypeLabel,
                                      style: AppTextStyles.bodySmall),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

// ─── Tutor Students Screen ───────────────────────────────────────────────────

class TutorStudentsScreen extends StatefulWidget {
  const TutorStudentsScreen({super.key});

  @override
  State<TutorStudentsScreen> createState() => _TutorStudentsScreenState();
}

class _TutorStudentsScreenState extends State<TutorStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getTutorStudents();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        setState(() {
          _students = List<Map<String, dynamic>>.from(res['data'] ?? []);
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered => _search.isEmpty
      ? _students
      : _students
          .where((s) => '${s['first_name']} ${s['last_name']}'
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 6, itemHeight: 70))
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No students found')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final s = _filtered[i];
                              final name =
                                  '${s['first_name']} ${s['last_name']}';
                              return ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TutorStudentProfileScreen(student: s),
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.secondary.withValues(alpha: 0.15),
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                title: Text(name, style: AppTextStyles.h4.copyWith(fontSize: 14)),
                                subtitle: Text(s['email'] ?? '',
                                    style: AppTextStyles.bodySmall),
                                trailing: StatusChip.fromStatus(
                                    s['enrollment_status'] ?? 'enrolled'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Tutor Announcements Screen ──────────────────────────────────────────────

class TutorAnnouncementsScreen extends StatefulWidget {
  const TutorAnnouncementsScreen({super.key});

  @override
  State<TutorAnnouncementsScreen> createState() =>
      _TutorAnnouncementsScreenState();
}

class _TutorAnnouncementsScreenState
    extends State<TutorAnnouncementsScreen> {
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final res = await ApiService.getTutorCourses();
    if (mounted) {
      final data = res['data'] as List? ?? [];
      setState(() => _courses = data.map((c) => Course.fromJson(c)).toList());
    }
  }

  Future<void> _sendAnnouncement() async {
    Course? selectedCourse;
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Announcement', style: AppTextStyles.h3),
              const SizedBox(height: 20),
              DropdownButtonFormField<Course?>(
                initialValue: selectedCourse,
                decoration:
                    const InputDecoration(labelText: 'Course (leave blank for all)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All My Courses')),
                  ..._courses.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.title, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (c) => setModal(() => selectedCourse = c),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Announcement Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Send Announcement',
                icon: Icons.campaign_rounded,
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      msgCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Title and message required'),
                        backgroundColor: AppColors.error));
                    return;
                  }
                  final res = await ApiService.createAnnouncement({
                    'title': titleCtrl.text.trim(),
                    'message': msgCtrl.text.trim(),
                    if (selectedCourse != null)
                      'course_id': selectedCourse!.id,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['error'] == null
                          ? 'Announcement sent!'
                          : res['error']),
                      backgroundColor: res['error'] == null
                          ? AppColors.success
                          : AppColors.error,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: const Center(
        child: EmptyState(
          icon: Icons.campaign_rounded,
          title: 'Send Announcements',
          subtitle: 'Tap the button below to notify your students.',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendAnnouncement,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Announcement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
