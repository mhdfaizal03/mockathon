import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access current theme
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding
                    Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme
                                  .lightGradient, // Beautiful Indigo gradient
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .animate()
                        .fade(duration: 600.ms)
                        .scale(delay: 200.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 48),

                    Text(
                          "MOCKATHON",
                          style: theme.textTheme.displayLarge!.copyWith(
                            letterSpacing: 4,
                            fontSize: 42,
                          ),
                        )
                        .animate()
                        .fade(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                          "Test What You Are Capable Of",
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        )
                        .animate()
                        .fade(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 64),

                    // Role Selection Cards
                    Text(
                      "Select Your Role",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ).animate().fade(delay: 700.ms),
                    const SizedBox(height: 32),

                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildRoleCard(
                              context,
                              title: "Admin",
                              icon: Icons.admin_panel_settings_rounded,
                              color: Colors.redAccent,
                            )
                            .animate()
                            .fade(delay: 800.ms)
                            .scale(delay: 800.ms, curve: Curves.easeOutBack),
                        _buildRoleCard(
                              context,
                              title: "Interviewer",
                              icon: Icons.edit_note_rounded,
                              color: AppTheme.primaryOrange,
                            )
                            .animate()
                            .fade(delay: 1000.ms)
                            .scale(delay: 1000.ms, curve: Curves.easeOutBack),
                        _buildRoleCard(
                              context,
                              title: "Candidate",
                              icon: Icons.school_rounded,
                              color: AppTheme.primaryIndigo,
                            )
                            .animate()
                            .fade(delay: 1200.ms)
                            .scale(delay: 1200.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(userType: title)),
        );
      },
      child: Container(
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.05,
              ), // Soft shadow for light theme
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
