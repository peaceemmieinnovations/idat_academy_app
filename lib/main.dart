import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'providers/auth_provider.dart';
import 'services/gamification_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/tutor/tutor_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GamificationService.initialize();
  await NotificationService.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const IdatAcademyApp());
}

// ─── Simple InheritedNotifier (replaces Provider package) ────────────────────
class AuthScope extends InheritedNotifier<AuthProvider> {
  const AuthScope({super.key, required AuthProvider auth, required super.child})
      : super(notifier: auth);

  static AuthProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  }
}

class IdatAcademyApp extends StatefulWidget {
  const IdatAcademyApp({super.key});
  @override
  State<IdatAcademyApp> createState() => _IdatAcademyAppState();
}

class _IdatAcademyAppState extends State<IdatAcademyApp> {
  final AuthProvider _auth = AuthProvider();

  @override
  void dispose() { _auth.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: _auth,
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        title: 'IDAT Academy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        if (auth.isStaffWorkspaceUser) return const TutorShell();
        return const StudentShell();
    }
  }
}
