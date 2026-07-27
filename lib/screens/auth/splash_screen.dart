import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, color: Colors.white, size: 72),
              SizedBox(height: 20),
              Text('IDAT Academy',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              SizedBox(height: 8),
              Text('Empowering Digital Futures',
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
              SizedBox(height: 48),
              CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2.5),
            ],
          ),
        ),
      ),
    );
  }
}
