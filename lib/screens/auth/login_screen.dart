import 'package:flutter/material.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../student/student_shell.dart';
import '../tutor/tutor_shell.dart';
import 'apply_screen.dart';
import '../../services/gamification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = AuthScope.of(context);
    bool success;
    if (_tabController.index == 0) {
      success = await auth.loginStudent(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      success = await auth.loginTutor(_emailCtrl.text.trim(), _passCtrl.text);
    }

    setState(() => _loading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else if (success && mounted) {
      _navigateAfterLogin(auth);
    }
  }

  void _navigateAfterLogin(AuthProvider auth) {
    if (auth.isStudent) GamificationService.recordLogin();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => auth.isTutor ? const TutorShell() : const StudentShell(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('IDAT Academy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('Empowering Digital Futures',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),

              // Card
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back!',
                              style: AppTextStyles.h1),
                          const SizedBox(height: 4),
                          const Text('Sign in to continue learning',
                              style: AppTextStyles.label),
                          const SizedBox(height: 24),

                          // Tab chooser
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: TabBar(
                              controller: _tabController,
                              onTap: (_) {
                                _emailCtrl.clear();
                                _passCtrl.clear();
                              },
                              indicator: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textGrey,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              unselectedLabelStyle: const TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 14),
                              tabs: const [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_rounded, size: 18),
                                      SizedBox(width: 6),
                                      Text('Student'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.badge_rounded,
                                          size: 18),
                                      SizedBox(width: 6),
                                      Text('Staff'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: AppColors.textGrey),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email required';
                              if (!v.contains('@')) return 'Enter valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: AppColors.textGrey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textGrey,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          GradientButton(
                            label: 'Sign In',
                            icon: Icons.login_rounded,
                            loading: _loading,
                            onPressed: _login,
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Apply Now button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 400),
                                  pageBuilder: (_, __, ___) => const ApplyScreen(),
                                  transitionsBuilder: (_, anim, __, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Apply Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // New student? Create Account
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 400),
                                    pageBuilder: (_, __, ___) => const ApplyScreen(),
                                    transitionsBuilder: (_, anim, __, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 1),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'New student? ',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                                  children: const [
                                    TextSpan(
                                      text: 'Create Account',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Demo Mode section
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.wifi_off_rounded,
                                        color: AppColors.success, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'API pending — Demo mode is active',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Log in instantly with demo accounts:',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _loading = true);
                                          final auth = AuthScope.of(context);
                                          final ok = await auth.loginStudent(
                                              'student@idat.com', 'idat123');
                                          setState(() => _loading = false);
                                          if (!ok && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(auth.error ?? 'Login failed'),
                                                backgroundColor: AppColors.error,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10)),
                                              ),
                                            );
                                          } else if (ok && mounted) {
                                            _navigateAfterLogin(auth);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors.success.withValues(alpha: 0.3)),
                                          ),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.person_rounded,
                                                  color: AppColors.success, size: 20),
                                              SizedBox(height: 4),
                                              Text(
                                                'Student Demo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                              Text(
                                                'student@idat.com',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _loading = true);
                                          final auth = AuthScope.of(context);
                                          final ok = await auth.loginTutor(
                                              'tutor@idat.com', 'idat123');
                                          setState(() => _loading = false);
                                          if (!ok && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(auth.error ?? 'Login failed'),
                                                backgroundColor: AppColors.error,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10)),
                                              ),
                                            );
                                          } else if (ok && mounted) {
                                            _navigateAfterLogin(auth);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.badge_rounded,
                                                  color: AppColors.primary, size: 20),
                                              SizedBox(height: 4),
                                              Text(
                                                'Staff Demo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              Text(
                                                'tutor@idat.com',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Password: idat123  ·  Data is sample only',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success.withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
