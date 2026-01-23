import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';

class ProfilePage extends StatelessWidget {
  final StudentModel student;

  const ProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final double contentPadding = isMobile ? 16 : 24;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header with Back Button
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: AppTheme.bentoDecoration(
                                color: AppTheme.cardLight,
                                radius: 20,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "My Profile",
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 24 : 32),

                      // 1. Hero Card (Dark Slate)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 24 : 32),
                        decoration: AppTheme.bentoDecoration(
                          color: AppTheme.bentoJacket,
                          radius: 40,
                        ),
                        child: Column(
                          children: [
                            // Avatar with glow effect
                            Container(
                              width: isMobile ? 100 : 120,
                              height: isMobile ? 100 : 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  student.name.isNotEmpty
                                      ? student.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: isMobile ? 40 : 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.bentoJacket,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              student.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                student.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Details Grid (Mockathon ID & Stack)
                      if (isMobile)
                        Column(
                          children: [
                            _buildInfoCard(
                              student.randomId,
                              "Mockathon ID",
                              Icons.fingerprint,
                              AppTheme.bentoAccent,
                              isMobile: true,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              student.stack.isNotEmpty
                                  ? student.stack
                                  : "General",
                              "Tech Stack",
                              Icons.layers_outlined,
                              AppTheme.cardLight,
                              isMobile: true,
                              iconColor: AppTheme.bentoJacket,
                              textColor: AppTheme.bentoJacket,
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                student.randomId,
                                "Mockathon ID",
                                Icons.fingerprint,
                                AppTheme.bentoAccent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                student.stack.isNotEmpty
                                    ? student.stack
                                    : "General",
                                "Tech Stack",
                                Icons.layers_outlined,
                                AppTheme.cardLight,
                                iconColor: AppTheme.bentoJacket,
                                textColor: AppTheme.bentoJacket,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildGuidelines(),
                      SafeArea(
                        child: Image.asset('assets/softlogo.png', height: 100),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    String value,
    String label,
    IconData icon,
    Color bgColor, {
    bool isMobile = false,
    Color iconColor = Colors.white,
    Color? textColor,
  }) {
    return Container(
      height: isMobile ? 160 : 180,
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(color: bgColor, radius: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isMobile
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconContainer(icon, iconColor, bgColor),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: (textColor ?? Colors.white).withOpacity(0.8),
                      ),
                    ),
                  ],
                )
              : _buildIconContainer(icon, iconColor, bgColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.white,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isMobile)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: (textColor ?? Colors.white).withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color, Color bg) {
    if (bg == AppTheme.cardLight) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bentoBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      );
    }
    return Icon(icon, color: color, size: 32);
  }

  Widget _buildGuidelines() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bentoJacket.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppTheme.bentoJacket,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Student Guidelines",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
