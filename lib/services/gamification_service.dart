import 'package:flutter/foundation.dart';

class GamificationState {
  final int xp;
  final int streak;
  final Set<String> badges;
  const GamificationState({this.xp = 240, this.streak = 4, this.badges = const {'First lesson'}});

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

/// Temporary in-memory game state. The backend should become the source of
/// truth when real student activity and cross-device syncing are available.
class GamificationService {
  static final ValueNotifier<GamificationState> state =
      ValueNotifier(const GamificationState());

  static void recordActivity(String activity) {
    final current = state.value;
    final badges = {...current.badges};
    var gained = 0;
    if (activity == 'lesson') {
      gained = 25;
      badges.add('Knowledge seeker');
    } else if (activity == 'assignment') {
      gained = 75;
      badges.add('First assignment');
    } else if (activity == 'night') {
      gained = 20;
      badges.add('Night owl');
    } else if (activity == 'course') {
      gained = 200;
      badges.add('Course finisher');
    }
    if (current.streak >= 7) badges.add('7-day streak');
    state.value = GamificationState(
      xp: current.xp + gained,
      streak: current.streak,
      badges: badges,
    );
  }

  static void recordLogin() {
    final current = state.value;
    state.value = GamificationState(
      xp: current.xp,
      streak: current.streak + 1,
      badges: current.badges,
    );
  }
}
