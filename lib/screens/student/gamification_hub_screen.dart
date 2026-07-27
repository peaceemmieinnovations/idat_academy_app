import 'package:flutter/material.dart';

import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import 'career_advisor_screen.dart';

class GamificationHubScreen extends StatelessWidget {
  const GamificationHubScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Learning Journey')),
        body: ValueListenableBuilder<GamificationState>(
          valueListenable: GamificationService.state,
          builder: (context, game, _) => ListView(padding: const EdgeInsets.all(20), children: [
            _LevelCard(game: game),
            const SizedBox(height: 20),
            Row(children: [
              _Metric(icon: Icons.local_fire_department_rounded, value: '${game.streak}', label: 'day streak', color: AppColors.warning),
              const SizedBox(width: 12),
              _Metric(icon: Icons.workspace_premium_rounded, value: '${game.badges.length}', label: 'badges', color: AppColors.accent),
            ]),
            const SizedBox(height: 24),
            const Text('Achievements', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              ...game.badges.map((badge) => _Badge(name: badge, unlocked: true)),
              const _Badge(name: 'Top scorer', unlocked: false),
              const _Badge(name: 'Speed learner', unlocked: false),
            ]),
            const SizedBox(height: 26),
            const Text('Weekly leaderboard', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text('Cybersecurity cohort • This week', style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            ...const [('1', 'Amara Okafor', '1,240 XP'), ('2', 'Tunde Bello', '980 XP'), ('3', 'You', '240 XP'), ('4', 'Chioma N.', '210 XP')].map((e) => _LeaderRow(rank: e.$1, name: e.$2, points: e.$3)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerAdvisorScreen())),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Open my career path'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showParty(context),
              icon: const Icon(Icons.celebration_rounded),
              label: const Text('Preview course completion party'),
            ),
            const SizedBox(height: 10),
            const Text('Demo controls: activity events unlock badges and add XP. Real activity will be recorded automatically by the backend.', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
        ),
      );

  void _showParty(BuildContext context) {
    GamificationService.recordActivity('course');
    showDialog(context: context, barrierDismissible: false, builder: (_) => const _CompletionParty());
  }
}

class _LevelCard extends StatelessWidget {
  final GamificationState game;
  const _LevelCard({required this.game});
  @override
  Widget build(BuildContext context) {
    final progress = game.xp / game.nextLevelXp;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CURRENT LEVEL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 11)),
      const SizedBox(height: 5), Text(game.level, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30)),
      const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 8, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white))),
      const SizedBox(height: 8), Text('${game.xp} XP • ${game.nextLevelXp - game.xp > 0 ? '${game.nextLevelXp - game.xp} XP to next level' : 'New level unlocked!'}', style: const TextStyle(color: Colors.white)),
    ]));
  }
}

class _Metric extends StatelessWidget { final IconData icon; final String value, label; final Color color; const _Metric({required this.icon, required this.value, required this.label, required this.color}); @override Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)), Text(label, style: AppTextStyles.bodySmall)])]))); }
class _Badge extends StatelessWidget { final String name; final bool unlocked; const _Badge({required this.name, required this.unlocked}); @override Widget build(BuildContext context) => Chip(avatar: Icon(unlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded, color: unlocked ? AppColors.accent : AppColors.textGrey, size: 18), label: Text(name), backgroundColor: unlocked ? AppColors.accent.withValues(alpha: .1) : AppColors.lightGrey); }
class _LeaderRow extends StatelessWidget { final String rank, name, points; const _LeaderRow({required this.rank, required this.name, required this.points}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: name == 'You' ? AppColors.secondary.withValues(alpha: .08) : Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(children: [Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 16), Expanded(child: Text(name, style: TextStyle(fontWeight: name == 'You' ? FontWeight.w800 : FontWeight.w600))), Text(points, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800))])); }
class _CompletionParty extends StatelessWidget { const _CompletionParty(); @override Widget build(BuildContext context) => AlertDialog(contentPadding: const EdgeInsets.all(28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('🎉  ✨  🎓', style: TextStyle(fontSize: 42)), const SizedBox(height: 16), const Text('Course completed!', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('You unlocked the Course Finisher badge and earned 200 XP.', textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.workspace_premium_rounded), label: const Text('View certificate'))])); }
