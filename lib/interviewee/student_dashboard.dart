import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mockathon/interviewee/profile_page.dart';
import 'package:mockathon/interviewee/notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/authentication/login_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Should be handled by AuthWrapper, but just in case:
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  StreamBuilder<StudentModel>(
                    stream: _dataService.getStudent(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text("Profile not found"));
                      }
                      final student = snapshot.data!;

                      return Column(
                        children: [
                          _buildHeader(context, student),
                          const SizedBox(height: 24),
                          _buildIDCard(student),
                          const SizedBox(height: 32),
                          _buildMarksSection(user.uid),
                        ],
                      );
                    },
                  ),
                  SafeArea(
                    child: Image.asset('assets/softlogo.png', height: 100),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentModel student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(student: student),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.bentoJacket.withOpacity(0.1),
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.bentoJacket,
                ),
              ),
            ),
          ),
          const Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          InkWell(
            onTap: () => _confirmLogout(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardLight,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.logout,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIDCard(StudentModel student) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: AppTheme.bentoDecoration(
                color: AppTheme.bentoJacket,
                radius: 36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud,
                        color: Colors.white,
                        size: isMobile ? 32 : 48,
                      ),
                      Flexible(
                        child: Text(
                          student.randomId,
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    student.stack,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<List<NotificationModel>>(
                        stream: _dataService.getNotifications('interviewee'),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationScreen(),
                                ),
                              );
                            },
                            child: _buildStat(
                              Icons.notifications,
                              "Alerts",
                              "$count",
                              isMobile: isMobile,
                            ),
                          );
                        },
                      ),
                      _buildStat(
                        Icons.calendar_today,
                        "Role",
                        "Candidate",
                        isMobile: isMobile,
                      ),
                      _buildStat(
                        Icons.school,
                        "Stack",
                        "Tech",
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fade(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildMarksSection(String uid) {
    return StreamBuilder<bool>(
      stream: _dataService.getResultsPublishedStream(),
      builder: (context, settingSnap) {
        final areResultsPublished = settingSnap.data ?? false;

        if (!areResultsPublished) {
          return Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.bentoDecoration(
              color: Colors.white,
              radius: 36,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "Results Pending",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The program is still in progress.\nResults will be published by the admin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<MarkModel?>(
          stream: _dataService.getMarks(uid),
          builder: (context, markSnap) {
            final marks = markSnap.data ?? MarkModel();

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildAptitudeCard(marks),
                      const SizedBox(height: 16),
                      _buildGdCard(marks),
                      const SizedBox(height: 16),
                      _buildHrCard(marks),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAptitudeCard(marks)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildGdCard(marks),
                          const SizedBox(height: 16),
                          _buildHrCard(marks),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAptitudeCard(MarkModel marks) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getMarkColor(marks.aptitude * 4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${marks.aptitude.toInt()} / 25",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.psychology, size: 64, color: Colors.grey),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aptitude",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                marks.aptitudeFeedback.isNotEmpty
                    ? marks.aptitudeFeedback
                    : "No feedback",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 600.ms).scale(curve: Curves.easeOutBack);
  }

  Widget _buildHrCard(MarkModel marks) {
    return Container(
          height: 180, // Increased height to accommodate feedback
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.bentoDecoration(
            color: _getMarkColor(marks.hr * 4),
            radius: 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search, color: Colors.white),
                      const SizedBox(height: 4),
                      const Text(
                        "Technical / HR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${marks.hr.toInt()} / 25",
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              if (marks.hrFeedback.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    marks.hrFeedback,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fade(delay: 200.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildGdCard(MarkModel marks) {
    return Container(
          height: 180, // Increased height
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.groups, color: Colors.grey),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "GD",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    "${marks.gd.toInt()} / 25",
                    style: TextStyle(
                      color: _getMarkColor(marks.gd * 4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    marks.gdFeedback.isNotEmpty
                        ? marks.gdFeedback
                        : "No feedback",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fade(delay: 400.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildStat(
    IconData icon,
    String label,
    String value, {
    bool isMobile = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: isMobile ? 16 : 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: isMobile ? 8 : 10,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(userType: "Interviewee"),
        ),
        (route) => false,
      );
    }
  }

  Color _getMarkColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.redAccent;
  }
}
