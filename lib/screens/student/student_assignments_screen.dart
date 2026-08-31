import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  List<Assignment> _assignments = [];
  bool _loading = true;
  String? _error;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentAssignments();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _assignments = data.map((a) => Assignment.fromJson(a)).toList();
          _loading = false;
        });
      }
    }
  }

  List<Assignment> get _pending =>
      _assignments.where((a) => a.submitted != true).toList();
  List<Assignment> get _submitted =>
      _assignments.where((a) => a.submitted == true).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Submitted (${_submitted.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 4, itemHeight: 120),
            )
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _AssignmentList(
                      assignments: _pending,
                      emptyTitle: 'All caught up!',
                      emptySubtitle: 'No pending assignments right now.',
                      emptyIcon: Icons.check_circle_outline_rounded,
                      onSubmit: _showSubmitDialog,
                    ),
                    _AssignmentList(
                      assignments: _submitted,
                      emptyTitle: 'No submissions yet',
                      emptySubtitle:
                          'Your submitted assignments will appear here.',
                      emptyIcon: Icons.assignment_outlined,
                    ),
                  ],
                ),
    );
  }

  Future<void> _showSubmitDialog(Assignment assignment) async {
    final textCtrl = TextEditingController();
    final speech = stt.SpeechToText();
    File? pickedFile;
    String? fileName;
    bool submitting = false;
    bool listening = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> toggleVoiceInput() async {
              if (listening) {
                await speech.stop();
                if (ctx.mounted) setModal(() => listening = false);
                return;
              }

              final available = await speech.initialize(
                onStatus: (status) {
                  if ((status == 'done' || status == 'notListening') &&
                      ctx.mounted) {
                    setModal(() => listening = false);
                  }
                },
                onError: (_) {
                  if (ctx.mounted) setModal(() => listening = false);
                },
              );
              if (!available) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text(
                        'Voice typing is unavailable. Please allow microphone and speech permissions.'),
                    backgroundColor: AppColors.error,
                  ));
                }
                return;
              }

              setModal(() => listening = true);
              await speech.listen(
                listenFor: const Duration(minutes: 2),
                pauseFor: const Duration(seconds: 4),
                onResult: (result) {
                  if (!ctx.mounted) return;
                  final transcript = result.recognizedWords;
                  textCtrl.value = textCtrl.value.copyWith(
                    text: transcript,
                    selection:
                        TextSelection.collapsed(offset: transcript.length),
                  );
                  setModal(() {});
                },
              );
            }

            return Container(

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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Submit Assignment', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(assignment.title, style: AppTextStyles.label),
              const SizedBox(height: 20),

              // File picker
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
                  );
                  if (result != null) {
                    setModal(() {
                      pickedFile = File(result.files.single.path!);
                      fileName = result.files.single.name;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: pickedFile != null
                            ? AppColors.success
                            : AppColors.lightGrey,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: pickedFile != null
                        ? AppColors.success.withValues(alpha: 0.05)
                        : AppColors.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                          pickedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          color: pickedFile != null
                              ? AppColors.success
                              : AppColors.textGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName ?? 'Tap to pick file (PDF, DOC, ZIP)',
                          style: TextStyle(
                              color: pickedFile != null
                                  ? AppColors.success
                                  : AppColors.textGrey,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Written or voice-transcribed response
              Row(
                children: [
                  Expanded(
                    child: Text('Assignment description',
                        style: AppTextStyles.h4),
                  ),
                  TextButton.icon(
                    onPressed: submitting ? null : toggleVoiceInput,
                    icon: Icon(listening
                        ? Icons.stop_circle_rounded
                        : Icons.mic_rounded),
                    label: Text(listening ? 'Stop' : 'Use voice'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          listening ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Text(
                listening
                    ? 'Listening… speak naturally, then tap Stop to review.'
                    : 'Type your response or use voice to transcribe it to text.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textCtrl,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Your typed or spoken response will appear here.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              GradientButton(
                label: 'Submit Assignment',
                icon: Icons.send_rounded,
                loading: submitting,
                onPressed: () async {
                  if (pickedFile == null && textCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please attach a file, type a response, or use voice input'),
                        backgroundColor: AppColors.error));
                    return;
                  }
                  setModal(() => submitting = true);
                  Map<String, dynamic> res;
                  if (pickedFile != null) {
                    res = await ApiService.uploadFile(
                      'student/assignments/${assignment.id}/submit',
                      pickedFile!,
                      {'typed_response': textCtrl.text.trim()},
                    );
                  } else {
                    res = await ApiService.post(
                        'student/assignments/${assignment.id}/submit',
                        {'typed_response': textCtrl.text.trim()});
                  }
                  setModal(() => submitting = false);
                  if (mounted) {
                    if (res['error'] == null) {
                      Navigator.pop(ctx);
                      GamificationService.recordActivity('assignment');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Assignment submitted!'),
                          backgroundColor: AppColors.success));
                      _load();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res['error'] ?? 'Submission failed'),
                          backgroundColor: AppColors.error));
                    }
                  }
                },
              ),
            ],
          ),
        );
          },
        ),
      );
    } finally {
      await speech.stop();
      textCtrl.dispose();
    }
  }
}

class _AssignmentList extends StatelessWidget {
  final List<Assignment> assignments;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final void Function(Assignment)? onSubmit;

  const _AssignmentList({
    required this.assignments,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return EmptyState(
          icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: assignments.length,
      itemBuilder: (_, i) {
        final a = assignments[i];
        final bool overdue = a.dueDate != null &&
            DateTime.tryParse(a.dueDate!)?.isBefore(DateTime.now()) == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
            border: Border.all(
              color: overdue && a.submitted != true
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.lightGrey,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(a.title,
                        style: AppTextStyles.h4,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (a.submitted == true && a.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${a.score?.toStringAsFixed(0)}/${a.maxScore.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ),
                ],
              ),
              if (a.courseTitle != null) ...[
                const SizedBox(height: 4),
                Text(a.courseTitle!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary)),
              ],
              if (a.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today_rounded,
                        size: 13,
                        color: overdue
                            ? AppColors.error
                            : AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_fmtDate(a.dueDate!)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: overdue
                              ? AppColors.error
                              : AppColors.textGrey,
                          fontWeight: overdue
                              ? FontWeight.w600
                              : FontWeight.w400),
                    ),
                  ],
                ),
              ],
              if (a.feedback != null && a.feedback!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.feedback!,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ],
              if (onSubmit != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onSubmit!(a),
                    child: const Text('Submit Assignment'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
