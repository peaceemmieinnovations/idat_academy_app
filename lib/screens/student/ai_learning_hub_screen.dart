import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Offline prototype for the AI learning tools. Replace the local responses
/// with calls to the AI API once lesson text extraction is available.
class AiLearningHubScreen extends StatefulWidget {
  const AiLearningHubScreen({super.key});

  @override
  State<AiLearningHubScreen> createState() => _AiLearningHubScreenState();
}

class _AiLearningHubScreenState extends State<AiLearningHubScreen> {
  int _tool = 0;
  final _question = TextEditingController();
  final _assignment = TextEditingController();
  String? _answer;
  String? _review;
  int _quizIndex = 0;
  int _score = 0;
  bool _answered = false;

  static const _questions = [
    ('Which practice best protects an account?', ['Reusing passwords', 'Using MFA', 'Sharing a PIN'], 1),
    ('What is phishing designed to do?', ['Speed up Wi-Fi', 'Steal information', 'Encrypt backups'], 1),
    ('What should you do before opening a suspicious link?', ['Verify the sender', 'Forward it', 'Enter your password'], 0),
  ];

  @override
  void dispose() {
    _question.dispose();
    _assignment.dispose();
    super.dispose();
  }

  void _ask() {
    final question = _question.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _answer = 'Based on your Cybersecurity Fundamentals lesson: start by identifying the asset, the threat, and the control. For "$question", review the section on multi-factor authentication and explain how it reduces account takeover risk.';
    });
  }

  void _reviewAssignment() {
    if (_assignment.text.trim().length < 20) return;
    setState(() {
      _review = 'Practice review — 78/100\n\nWhat works: your answer has a clear main idea.\nImprove next: add one real example, define the key term in the first paragraph, and finish with a short conclusion.\n\nThis is guidance only; your tutor gives the final score.';
    });
  }

  void _choose(int option) {
    if (_answered) return;
    setState(() {
      _answered = true;
      if (option == _questions[_quizIndex].$3) _score++;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_quizIndex < _questions.length - 1) {
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
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF9333EA)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.auto_awesome_rounded, color: Colors.white), SizedBox(width: 8), Text('AI-powered learning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))]),
                SizedBox(height: 8),
                Text('Cybersecurity Fundamentals • Demo lesson context', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(tools.length, (i) => ChoiceChip(
                avatar: Icon(tools[i].$1, size: 18, color: _tool == i ? Colors.white : AppColors.secondary),
                label: Text(tools[i].$2),
                selected: _tool == i,
                selectedColor: AppColors.secondary,
                labelStyle: TextStyle(color: _tool == i ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                onSelected: (_) => setState(() => _tool = i),
              )),
            ),
            const SizedBox(height: 22),
            _buildTool(),
            const SizedBox(height: 20),
            const Text('Demo mode: responses use sample lesson context. Connect an AI API and extracted lesson text before using this with learners.', style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildTool() {
    switch (_tool) {
      case 0:
        return _panel('Study Companion', 'Ask about this lesson, in your own words.', [
          TextField(controller: _question, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'e.g. Why is multi-factor authentication important?')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _ask, icon: const Icon(Icons.send_rounded), label: const Text('Ask about this lesson')),
          if (_answer != null) _result('AI response', _answer!),
        ]);
      case 1:
        return _panel('Assignment Reviewer', 'Get practice feedback before you submit. Your tutor remains the final grader.', [
          TextField(controller: _assignment, minLines: 7, maxLines: 10, decoration: const InputDecoration(hintText: 'Paste your draft answer here...')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _reviewAssignment, icon: const Icon(Icons.auto_fix_high_rounded), label: const Text('Review my draft')),
          if (_review != null) _result('Practice feedback', _review!),
        ]);
      case 2:
        return _panel('2-minute lesson summary', 'Cybersecurity Fundamentals • Account security', const [
          _SummaryPoint('Use strong, unique passwords', 'A password manager makes this practical.'),
          _SummaryPoint('Turn on multi-factor authentication', 'It adds a second proof of identity if a password is exposed.'),
          _SummaryPoint('Pause before clicking', 'Phishing messages create urgency. Verify the sender and link first.'),
          _SummaryPoint('Report suspicious activity', 'Early reporting protects you and the organisation.'),
        ]);
      default:
        final question = _questions[_quizIndex];
        return _panel('Test yourself', 'Question ${_quizIndex + 1} of ${_questions.length} • Score: $_score', [
          Text(question.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...List.generate(question.$2.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => _choose(i),
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(14), side: BorderSide(color: _answered && i == question.$3 ? AppColors.success : AppColors.lightGrey)),
              child: Text(question.$2[i]),
            ),
          )),
          if (_answered) ...[
            Text(' ${_score > 0 && question.$3 == 1 ? 'Nice work.' : 'Answer: ${question.$2[question.$3]}'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            FilledButton(onPressed: _nextQuestion, child: Text(_quizIndex == _questions.length - 1 ? 'Restart quiz' : 'Next question')),
          ],
        ]);
    }
  }

  Widget _panel(String title, String subtitle, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.h3), const SizedBox(height: 4), Text(subtitle, style: AppTextStyles.bodySmall), const SizedBox(height: 16), ...children]),
  );

  Widget _result(String title, String content) => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary)), const SizedBox(height: 8), Text(content, style: const TextStyle(height: 1.45))]));
}

class _SummaryPoint extends StatelessWidget {
  final String title;
  final String detail;
  const _SummaryPoint(this.title, this.detail);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20), const SizedBox(width: 10), Expanded(child: RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '$title. ', style: const TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: detail)])))]));
}
