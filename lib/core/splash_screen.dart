import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/main.dart'; // For AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      height: 200,
                      width: 200,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            AppTheme.lightGradient, // Professional Gradient
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset("assets/Mockuplogo.png"),
                    )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(delay: 200.ms, curve: Curves.easeOutBack),
              ],
            ),
          ),

          // Bottom Logo
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Image.asset(
                'assets/softlogo.png',
                width: 100,
                fit: BoxFit.contain,
              ).animate().fade(delay: 500.ms, duration: 800.ms),
            ),
          ),
        ],
      ),
    );
  }
}
