import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CareerAdvisorScreen extends StatelessWidget {
  const CareerAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Career Path Advisor')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.explore_rounded, color: Colors.white, size: 34),
              SizedBox(height: 12),
              Text('Your next best move', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21)),
              SizedBox(height: 5),
              Text('A focused roadmap based on your current learning progress.', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 24),
          const _CareerCard(icon: Icons.work_outline_rounded, color: AppColors.secondary, title: 'Recommended direction', body: 'Junior Cybersecurity Analyst', caption: 'Strong match for your Cybersecurity Fundamentals progress.'),
          const _CareerCard(icon: Icons.school_rounded, color: AppColors.success, title: 'Learn next', body: 'Network Security and Linux basics', caption: 'These skills will strengthen your job readiness.'),
          const _CareerCard(icon: Icons.construction_rounded, color: AppColors.warning, title: 'Build this week', body: 'Create a small security checklist', caption: 'Add it to a portfolio with a short explanation of your decisions.'),
          const _CareerCard(icon: Icons.search_rounded, color: AppColors.accent, title: 'Jobs to explore', body: 'SOC Analyst • IT Support • Security Intern', caption: 'Start with internships and junior roles while completing your pathway.'),
          const SizedBox(height: 10),
          const Text('Demo roadmap: connect real course completion, grades, skills and available roles to your AI service for personalized recommendations.', style: TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.4)),
        ]),
      );
}

class _CareerCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String caption;
  const _CareerCard({required this.icon, required this.color, required this.title, required this.body, required this.caption});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: .07), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: .18))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(body, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 4), Text(caption, style: AppTextStyles.bodySmall)])),
        ]),
      );
}
