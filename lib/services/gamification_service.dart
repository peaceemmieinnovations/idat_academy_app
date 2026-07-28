import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GamificationState {
  final int xp;
  final int streak;
  final Set<String> badges;
  final DateTime? lastActivityDate;

  const GamificationState({
    this.xp = 240,
    this.streak = 0,
    this.badges = const {'First lesson'},
    this.lastActivityDate,
  });

  String get level {
    if (xp >= 2000) return 'Legend';
    if (xp >= 1200) return 'Expert';
    if (xp >= 700) return 'Pro';
    if (xp >= 300) return 'Explorer';
    return 'Beginner';
  }

  int get nextLevelXp {
    if (xp < 300) return 300;
    if (xp < 700) return 700;
    if (xp < 1200) return 1200;
    return 2000;
  }
}

/// Keeps learning progress available between app launches. When the backend
/// exposes achievement endpoints, these same values can be exchanged there.
class GamificationService {
  static const _storage = FlutterSecureStorage();
  static const _xpKey = 'game_xp';
  static const _streakKey = 'game_streak';
  static const _badgesKey = 'game_badges';
  static const _lastActivityKey = 'game_last_activity';

  static final ValueNotifier<GamificationState> state =
      ValueNotifier(const GamificationState());
  static bool _loaded = false;

  static Future<void> initialize() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final values = await _storage.readAll();
      final badges = (values[_badgesKey] ?? 'First lesson')
          .split('|')
          .where((badge) => badge.isNotEmpty)
          .toSet();
      state.value = GamificationState(
        xp: int.tryParse(values[_xpKey] ?? '') ?? 240,
        streak: int.tryParse(values[_streakKey] ?? '') ?? 0,
        badges: badges,
        lastActivityDate: DateTime.tryParse(values[_lastActivityKey] ?? ''),
      );
    } catch (_) {
      // Progress still works for the current session if secure storage is off.
    }
  }

  static Future<void> recordLogin() => recordActivity('login');

  static Future<void> recordActivity(String activity) async {
    await initialize();
    final current = state.value;
    final today = _day(DateTime.now());
    final last = current.lastActivityDate == null
        ? null
        : _day(current.lastActivityDate!);
    var streak = current.streak;
    final badges = {...current.badges};

    if (last == null || last != today) {
      streak = last != null && today.difference(last).inDays == 1
          ? streak + 1
          : 1;
      if (streak >= 3) badges.add('3-day streak');
      if (streak >= 7) badges.add('7-day streak');
      if (streak >= 30) badges.add('30-day streak');
    }

    var gained = 0;
    switch (activity) {
      case 'lesson':
        gained = 25;
        badges.add('Knowledge seeker');
      case 'assignment':
        gained = 75;
        badges.add('First assignment');
      case 'night':
        gained = 20;
        badges.add('Night owl');
      case 'course':
        gained = 200;
        badges.add('Course finisher');
      case 'login':
        gained = last == today ? 0 : 10;
    }

    state.value = GamificationState(
      xp: current.xp + gained,
      streak: streak,
      badges: badges,
      lastActivityDate: today,
    );
    await _persist();
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Future<void> _persist() async {
    final current = state.value;
    try {
      await _storage.write(key: _xpKey, value: '${current.xp}');
      await _storage.write(key: _streakKey, value: '${current.streak}');
      await _storage.write(key: _badgesKey, value: current.badges.join('|'));
      await _storage.write(
        key: _lastActivityKey,
        value: current.lastActivityDate?.toIso8601String(),
      );
    } catch (_) {
      // Do not interrupt learning if local persistence is unavailable.
    }
  }
}
