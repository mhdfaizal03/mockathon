import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/authentication/welcome_page.dart';

import 'package:mockathon/interviewee/profile_page.dart';

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
    final user = _authService.currentUser;
    if (user == null) return const WelcomePage();

    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // StreamBuilder wraps everything
              StreamBuilder<StudentModel>(
                stream: _dataService.getStudent(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final student = snapshot.data!;

                  return Column(
                    children: [
                      // 1. Header (Pill Style)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
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
                                    builder: (context) =>
                                        ProfilePage(student: student),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.bentoJacket
                                    .withOpacity(0.1),
                                child: Text(
                                  student.name.isNotEmpty
                                      ? student.name[0].toUpperCase()
                                      : '?',
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
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
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
                      ),
                      const SizedBox(height: 20),

                      // 2. Main ID Card (Weather Style) - Dark Slate
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                                const Icon(
                                  Icons.cloud,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                Text(
                                  student.randomId,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              student.stack,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStat(
                                  Icons.notifications,
                                  "Alerts",
                                  "${student.notifications.length}",
                                ),
                                _buildStat(
                                  Icons.calendar_today,
                                  "Role",
                                  "Student",
                                ),
                                _buildStat(Icons.school, "Stack", "Tech"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Bento Grid for Marks (Conditional)
                      StreamBuilder<bool>(
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
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
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
                            stream: _dataService.getMarks(user.uid),
                            builder: (context, markSnap) {
                              final marks = markSnap.data ?? MarkModel();

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column (Tall Vertical Card)
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      height: 280,
                                      padding: const EdgeInsets.all(20),
                                      decoration: AppTheme.bentoDecoration(
                                        color: Colors.white,
                                        radius: 36,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bentoJacket,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "${marks.aptitude.toInt()}%",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Placeholder illustration or icon
                                          const Center(
                                            child: Icon(
                                              Icons.psychology,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                marks
                                                        .aptitudeFeedback
                                                        .isNotEmpty
                                                    ? marks.aptitudeFeedback
                                                    : "No feedback",
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Right Center Column
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        // Top Horizontal (Accent Color)
                                        Container(
                                          height: 120,
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(20),
                                          decoration: AppTheme.bentoDecoration(
                                            color: AppTheme.bentoAccent,
                                            radius: 36,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.person_search,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text(
                                                    "HR",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "${marks.hr.toInt()}",
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Bottom Vertical
                                        Container(
                                          height: 144,
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(20),
                                          decoration: AppTheme.bentoDecoration(
                                            color: Colors.white,
                                            radius: 36,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Align(
                                                alignment: Alignment.topRight,
                                                child: Icon(
                                                  Icons.groups,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "GD",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF333333),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${marks.gd.toInt()} marks",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
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
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }
}
