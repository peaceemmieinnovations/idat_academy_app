import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF2D0A6B), AppColors.secondary],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 64),
                      ),
                      const SizedBox(height: 28),
                      const Text('IDAT Academy',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('Empowering Digital Futures',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 16,
                              fontWeight: FontWeight.w400)),
                      const SizedBox(height: 48),
                      const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
