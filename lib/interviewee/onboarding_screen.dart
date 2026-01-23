import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/interviewee/nav_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DataService dataService = DataService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.bentoDecoration(
                      color: AppTheme.bentoJacket,
                      radius: 40,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 64,
                    ),
                  ).animate().scale(
                    curve: Curves.easeOutBack,
                    duration: 600.ms,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Welcome to Mockathon",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ).animate().fade(delay: 200.ms),
                  const SizedBox(height: 8),
                  const Text(
                    "Please review the guidelines before you begin",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ).animate().fade(delay: 300.ms),
                  const SizedBox(height: 48),
                  _buildGuidelinesCard(),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () async {
                      if (user != null) {
                        await dataService.completeOnboarding(user.uid);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NavScreen(),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bentoJacket,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "START JOURNEY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Guidelines",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildGuidelineItem(
            Icons.check_circle_outline,
            "Formal dress code is mandatory",
          ),
          _buildGuidelineItem(
            Icons.description_outlined,
            "Carry updated resume (minimum 2 copies)",
          ),
          _buildGuidelineItem(
            Icons.card_membership_outlined,
            "Carry one copy of certificates",
          ),
          _buildGuidelineItem(Icons.edit_outlined, "Carry a pen"),
          _buildGuidelineItem(
            Icons.timer_outlined,
            "Be punctual for all rounds",
          ),
          _buildGuidelineItem(
            Icons.psychology_outlined,
            "Follow instructions strictly at every stage",
          ),
          _buildGuidelineItem(
            Icons.volunteer_activism_outlined,
            "Maintain professional behavior throughout",
          ),
        ],
      ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bentoJacket.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.bentoJacket),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
