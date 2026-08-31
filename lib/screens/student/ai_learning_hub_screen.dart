import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// AI Study Companion for the IDAT Academy app. Every tool talks to the
/// academy API (POST /api/ai/ask, /ai/review, /ai/summary, /ai/quiz), which
/// builds the prompt server-side and returns JSON only.
class AiLearningHubScreen extends StatefulWidget {
  final int? lessonId;
  final String? lessonTitle;
  final String? lessonTopic;
  final String? lessonContent;

  const AiLearningHubScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
    this.lessonTopic,
    this.lessonContent,
  });

  @override
  State<AiLearningHubScreen> createState() => _AiLearningHubScreenState();
}

class _AiLearningHubScreenState extends State<AiLearningHubScreen> {
  int _tool = 0;
  final _question = TextEditingController();
  final _assignment = TextEditingController();

  // Ask AI
  String? _answer;

  // Assignment reviewer
  String? _review;

  // Summary
  String? _summary;
  List<String> _keyPoints = [];

  // Quiz
  List<Map<String, dynamic>> _quizQuestions = [];
  String _difficulty = 'medium';
  int _quizIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _loadingQuiz = false;

  bool _loading = false;
  String? _error;

  // Lesson selection — used when the studio is opened without a lesson
  // context (e.g. from the dashboard banner).
  List<Course> _courses = [];
  List<Lesson> _lessons = [];
  int? _courseId;
  int? _lessonId;
  bool _loadingContext = false;

  @override
  void initState() {
    super.initState();
    if (widget.lessonId == null) _loadStudyContext();
  }

  Course? get _selectedCourse => _courses.isEmpty
      ? null
      : _courses.firstWhere((c) => c.id == _courseId,
          orElse: () => _courses.first);

  Lesson? get _selectedLesson => _lessons.isEmpty
      ? null
      : _lessons.firstWhere((l) => l.id == _lessonId,
          orElse: () => _lessons.first);

  int? get _effectiveLessonId => widget.lessonId ?? _selectedLesson?.id;

  String? get _effectiveLessonTitle {
    if (widget.lessonTitle?.isNotEmpty ?? false) return widget.lessonTitle;
    return _selectedLesson?.title;
  }

  String? get _effectiveLessonTopic {
    if (widget.lessonTopic?.isNotEmpty ?? false) return widget.lessonTopic;
    return _selectedCourse?.title;
  }

  String? get _effectiveLessonContent {
    if (widget.lessonContent?.isNotEmpty ?? false) {
      return widget.lessonContent;
    }
    return _selectedLesson?.description;
  }

  Future<void> _loadStudyContext() async {
    setState(() => _loadingContext = true);
    final res = await ApiService.getStudentCourses();
    if (!mounted) return;
    final courses = (res['data'] as List? ?? const [])
        .whereType<Map>()
        .map((c) => Course.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    setState(() {
      _courses = courses;
      _loadingContext = false;
      if (courses.isNotEmpty && _courseId == null) {
        _courseId = courses.first.id;
      }
    });
    if (_courseId != null) await _loadLessonsFor(_courseId!);
  }

  Future<void> _loadLessonsFor(int courseId) async {
    setState(() => _loadingContext = true);
    final res = await ApiService.getStudentLessons(courseId);
    if (!mounted) return;
    final lessons = (res['data'] as List? ?? const [])
        .whereType<Map>()
        .map((l) => Lesson.fromJson(Map<String, dynamic>.from(l)))
        .toList();
    setState(() {
      _lessons = lessons;
      _loadingContext = false;
      if (lessons.isNotEmpty && _lessonId == null) {
        _lessonId = lessons.first.id;
      }
    });
  }

  void _onCourseChanged(int? courseId) {
    if (courseId == null) return;
    setState(() {
      _courseId = courseId;
      _lessonId = null;
      _lessons = [];
    });
    _loadLessonsFor(courseId);
  }

  void _onLessonChanged(int? lessonId) {
    setState(() => _lessonId = lessonId);
  }

  @override
  void dispose() {
    _question.dispose();
    _assignment.dispose();
    super.dispose();
  }

  bool get _hasLessonContext =>
      (_effectiveLessonTitle?.isNotEmpty ?? false) ||
      (_effectiveLessonTopic?.isNotEmpty ?? false);

  String? get _contextLabel {
    final title = _effectiveLessonTitle;
    final topic = _effectiveLessonTopic;
    if (title != null && title.isNotEmpty) {
      return topic == null || topic.isEmpty ? title : '$title • $topic';
    }
    if (topic != null && topic.isNotEmpty) return topic;
    return null;
  }

  Future<void> _ask() async {
    final question = _question.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
    });
    final result = await ApiService.askLessonAi(
      lessonId: _effectiveLessonId,
      lessonTitle: _effectiveLessonTitle,
      lessonTopic: _effectiveLessonTopic,
      lessonContent: _effectiveLessonContent,
      question: question,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['error'] != null) {
        _error = result['error'].toString();
      } else {
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : result;
        _answer = data['answer']?.toString() ?? 'No answer returned.';
      }
    });
  }

  Future<void> _reviewAssignment() async {
    final draft = _assignment.text.trim();
    if (draft.length < 20) {
      setState(() => _error =
          'Write at least a few sentences so the reviewer has something to work with.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _review = null;
    });
    final result = await ApiService.reviewAssignmentAi(
      lessonId: _effectiveLessonId,
      lessonTitle: _effectiveLessonTitle,
      lessonTopic: _effectiveLessonTopic,
      lessonContent: _effectiveLessonContent,
      assignmentAnswer: draft,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['error'] != null) {
        _error = result['error'].toString();
      } else {
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : result;
        final buffer = StringBuffer();
        final score = data['score'];
        if (score != null) {
          buffer.writeln('Practice score: $score/10');
        }
        final feedback = data['overall_feedback']?.toString().trim();
        if (feedback != null && feedback.isNotEmpty) {
          buffer.writeln();
          buffer.writeln(feedback);
        }
        final strengths = (data['strengths'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        if (strengths.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('What works well:');
          for (final s in strengths) {
            buffer.writeln('• $s');
          }
        }
        final weaknesses = (data['weaknesses'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        if (weaknesses.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('To improve:');
          for (final s in weaknesses) {
            buffer.writeln('• $s');
          }
        }
        final suggestions = (data['suggestions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        if (suggestions.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('Suggested next steps:');
          for (final s in suggestions) {
            buffer.writeln('• $s');
          }
        }
        _review = buffer.toString().trim().isEmpty
            ? 'Review complete.'
            : buffer.toString().trim();
      }
    });
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
      _keyPoints = [];
    });
    final result = await ApiService.getLessonAiSummary(
      lessonId: _effectiveLessonId,
      lessonTitle: _effectiveLessonTitle,
      lessonTopic: _effectiveLessonTopic,
      lessonContent: _effectiveLessonContent,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['error'] != null) {
        _error = result['error'].toString();
      } else {
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : result;
        _summary = data['summary']?.toString() ?? 'No summary returned.';
        _keyPoints = (data['key_points'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
      }
    });
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loadingQuiz = true;
      _error = null;
      _quizQuestions = [];
    });
    final result = await ApiService.getLessonAiQuiz(
      lessonId: _effectiveLessonId,
      lessonTitle: _effectiveLessonTitle,
      lessonTopic: _effectiveLessonTopic,
      lessonContent: _effectiveLessonContent,
      difficulty: _difficulty,
      count: 5,
    );
    if (!mounted) return;
    setState(() {
      _loadingQuiz = false;
      if (result['error'] != null) {
        _error = result['error'].toString();
      } else {
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : result;
        _quizQuestions = (data['questions'] as List? ?? [])
            .whereType<Map>()
            .map((q) => Map<String, dynamic>.from(q))
            .toList();
        _quizIndex = 0;
        _score = 0;
        _answered = false;
      }
    });
  }

  int _correctOption(Map<String, dynamic> q) {
    final correct = '${q['correct_answer'] ?? ''}'.trim().toUpperCase();
    final options = (q['options'] as List? ?? [])
        .map((o) => o.toString().trim())
        .toList();
    if (correct.isEmpty || options.isEmpty) return -1;
    for (var i = 0; i < options.length; i++) {
      if (options[i].toUpperCase().startsWith(correct)) return i;
    }
    final idx = correct.codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (idx >= 0 && idx < options.length) return idx;
    return -1;
  }

  void _choose(int option) {
    if (_answered || _quizQuestions.isEmpty) return;
    final correct = _correctOption(_quizQuestions[_quizIndex]);
    setState(() {
      _answered = true;
      if (option == correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_quizQuestions.isEmpty) return;
    setState(() {
      if (_quizIndex < _quizQuestions.length - 1) {
        _quizIndex++;
        _answered = false;
      } else {
        _quizIndex = 0;
        _answered = false;
        _score = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tools = [
      (Icons.auto_awesome_rounded, 'Ask AI'),
      (Icons.rate_review_rounded, 'Review work'),
      (Icons.summarize_rounded, '2-min summary'),
      (Icons.quiz_rounded, 'Test myself'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('AI Learning Studio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'AI-powered learning',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _contextLabel ??
                        'Answer questions, get feedback, summaries and quizzes.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.lessonId == null) ...[
              _buildLessonSelector(),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(tools.length, (i) => ChoiceChip(
                avatar: Icon(tools[i].$1,
                    size: 18,
                    color:
                        _tool == i ? Colors.white : AppColors.secondary),
                label: Text(tools[i].$2),
                selected: _tool == i,
                selectedColor: AppColors.secondary,
                labelStyle: TextStyle(
                    color: _tool == i ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700),
                onSelected: (_) => setState(() => _tool = i),
              )),
            ),
            const SizedBox(height: 22),
            _buildTool(),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error, height: 1.4)),
              ),
            const Text(
              'AI responses are generated from lesson content supplied by the academy server. Practice feedback is not a tutor grade.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonSelector() {
    if (_loadingContext) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.secondary),
        ),
      );
    }
    if (_courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'No enrolled courses yet. Register for a course to use the AI study tools.',
          style:
              TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study material',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _courseId,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items: _courses
                .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.title, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: _onCourseChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _lessonId,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Lesson',
              border: OutlineInputBorder(),
            ),
            items: _lessons
                .map((l) => DropdownMenuItem<int>(
                    value: l.id,
                    child: Text(l.title, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: _onLessonChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTool() {
    switch (_tool) {
      case 0:
        return _panel(
          'Study Companion',
          _hasLessonContext
              ? 'Ask about this lesson, in your own words.'
              : 'Ask about any lesson topic, in your own words.',
          [
            TextField(
                controller: _question,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                    hintText:
                        'e.g. Why is multi-factor authentication important?')),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _loading ? null : _ask,
                icon: const Icon(Icons.send_rounded),
                label: Text(_loading ? 'Thinking…' : 'Ask about this lesson')),
            if (_answer != null) _result('AI response', _answer!),
          ],
        );
      case 1:
        return _panel(
          'Assignment Reviewer',
          'Get practice feedback before you submit. Your tutor remains the final grader.',
          [
            TextField(
                controller: _assignment,
                minLines: 7,
                maxLines: 10,
                decoration: const InputDecoration(
                    hintText: 'Paste your draft answer here...')),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _loading ? null : _reviewAssignment,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text(_loading ? 'Reviewing…' : 'Review my draft')),
            if (_review != null) _result('Practice feedback', _review!),
          ],
        );
      case 2:
        return _panel('2-minute lesson summary', _contextLabel ?? 'Lesson summary', [
          FilledButton.icon(
            onPressed: _loading ? null : _loadSummary,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_loading ? 'Summarising…' : 'Generate summary'),
          ),
          if (_summary != null) ...[
            const SizedBox(height: 16),
            _result('Summary', _summary!),
          ],
          if (_keyPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._keyPoints
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p,
                                style: const TextStyle(height: 1.4)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ]);
      default:
        return _buildQuizPanel();
    }
  }

  Widget _buildQuizPanel() {
    if (_loadingQuiz) {
      return _panel('Test yourself', 'Generating questions…', [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
        ),
      ]);
    }
    if (_quizQuestions.isEmpty) {
      return _panel('Test yourself', 'Generate a quick quiz on this lesson.', [
        DropdownButtonFormField<String>(
          initialValue: _difficulty,
          decoration: const InputDecoration(
              labelText: 'Difficulty', isDense: true),
          items: const [
            DropdownMenuItem(value: 'easy', child: Text('Easy')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'hard', child: Text('Hard')),
          ],
          onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _loadQuiz,
          icon: const Icon(Icons.quiz_rounded),
          label: const Text('Start quiz'),
        ),
      ]);
    }

    final question = _quizQuestions[_quizIndex];
    final qText = question['question']?.toString() ?? '';
    final options = (question['options'] as List? ?? [])
        .map((o) => o.toString())
        .toList();
    final correct = _correctOption(question);
    final explanation = question['explanation']?.toString();

    return _panel(
      'Test yourself',
      'Question ${_quizIndex + 1} of ${_quizQuestions.length} • Score: $_score',
      [
        Text(qText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...List.generate(options.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => _choose(i),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(14),
              side: BorderSide(
                color: _answered && i == correct
                    ? AppColors.success
                    : AppColors.lightGrey,
              ),
            ),
            child: Text(options[i]),
          ),
        )),
        if (_answered) ...[
          Text(
            correct >= 0 && correct < options.length
                ? 'Answer: ${options[correct]}'
                : 'Answered.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(explanation,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.4)),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _nextQuestion,
            child: Text(_quizIndex == _quizQuestions.length - 1
                ? 'Restart quiz'
                : 'Next question'),
          ),
        ],
      ],
    );
  }

  Widget _panel(String title, String subtitle, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _result(String title, String content) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(height: 1.45)),
          ],
        ),
      );
}
