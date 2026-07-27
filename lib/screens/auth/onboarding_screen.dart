import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _currentPage = 0;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      icon: Icons.school_rounded,
      title: 'Welcome to\nIDAT Academy',
      subtitle: 'Your journey to becoming a digital professional starts here.',
      color: AppColors.primary,
    ),
    _OnboardSlide(
      icon: Icons.menu_book_rounded,
      title: 'Learn from\nIndustry Experts',
      subtitle: 'Access world-class courses in AI, Cyber Security, Digital Marketing & more.',
      color: AppColors.secondary,
    ),
    _OnboardSlide(
      icon: Icons.workspace_premium_rounded,
      title: 'Earn\nCertifications',
      subtitle: 'Get certified and build your career with internationally recognized qualifications.',
      color: Color(0xFF0D9488),
    ),
    _OnboardSlide(
      icon: Icons.rocket_launch_rounded,
      title: 'Start Your\nDigital Future',
      subtitle: 'Apply now and join a community of 500+ students transforming their careers.',
      color: Color(0xFFE11D48),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              slide.color,
              slide.color.withValues(alpha: 0.7),
              AppColors.primary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),

              // Bottom section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 32 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next / Get Started button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: TextStyle(
                                  color: slide.color,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _slides.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                color: slide.color,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign in link
                    GestureDetector(
                      onTap: _goToLogin,
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardSlide slide) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    slide.icon,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Subtitle
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
