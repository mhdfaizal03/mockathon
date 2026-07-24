import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/core/app_config.dart';

import 'package:mockathon/interviewee/profile_page.dart';
import 'package:mockathon/interviewee/notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mockathon/services/resume_service.dart';
import 'dart:typed_data';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Session Expired"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginPage(userType: "Interviewee"),
                        ),
                      );
                    },
                    child: const Text("Go to Login"),
                  ),
                ],
              ),
            ),
          );
        }

        // Pass the user ID to the content widget.
        // Using ValueKey ensures that if the user changes (e.g. relogin),
        // the state is reset and streams are re-initialized.
        return _DashboardContent(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final String uid;

  const _DashboardContent({super.key, required this.uid});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();
  final ResumeService _resumeService = ResumeService();

  bool _isUploading = false;
  late Stream<StudentModel> _studentStream;
  late Stream<MarkModel?> _marksStream;
  late Stream<List<NotificationModel>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _studentStream = _dataService.getStudent(widget.uid);
    // _resultsPublishedStream will be handled inside build to ensure branch context
    _marksStream = _dataService.getMarks(widget.uid);
    _notificationStream = _dataService.getNotifications('interviewee');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.warmBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    StreamBuilder<StudentModel>(
                      stream: _studentStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Error loading dashboard: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final student = snapshot.data!;

                        return StreamBuilder<String?>(
                          stream: _dataService.getActiveMockathonIdStream(branch: student.branch),
                          builder: (context, activeMockathonSnap) {
                            if (activeMockathonSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final activeMockathonId = activeMockathonSnap.data;

                            return Column(
                              children: [
                                _buildHeader(context, student),
                                const SizedBox(height: 12),
                                _buildIDCard(student),
                                const SizedBox(height: 16),
                                
                                if (student.mockathonId == null || activeMockathonId == null) ...[
                                  _buildBeforeMockathonState(),
                                ] else if (student.mockathonId != activeMockathonId) ...[
                                  _buildAlreadyAttendedState(),
                                  const SizedBox(height: 16),
                                  _buildCVSection(context, student),
                                  const SizedBox(height: 16),
                                  _buildMarksSection(widget.uid, student.branch),
                                ] else ...[
                                  _buildCVSection(context, student),
                                  const SizedBox(height: 16),
                                  _buildMarksSection(widget.uid, student.branch),
                                ],
                                if (student.mockathonHistory.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _buildHistorySection(student),
                                ],
                              ],
                            );
                          },
                        );
                      },
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

  Widget _buildHeader(BuildContext context, StudentModel student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 30,
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
              radius: 20,
              backgroundColor: AppTheme.bentoJacket.withValues(alpha: 0.1),
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
              fontSize: 16,
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
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.logout,
                size: 18,
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
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: AppTheme.bentoDecoration(
                color: AppTheme.bentoJacket,
                radius: 30,
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
                        size: isMobile ? 24 : 32,
                      ),
                      Flexible(
                        child: Text(
                          student.randomId,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    student.stack,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<List<NotificationModel>>(
                        stream: _notificationStream,
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
                        Icons.location_on,
                        "Branch",
                        student.branch,
                        isMobile: isMobile,
                      ),
                      _buildStat(
                        Icons.school,
                        "Stack",
                        student.stack,
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

  Widget _buildBeforeMockathonState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 30),
      child: Column(
        children: [
          const Icon(Icons.event_available, size: 64, color: AppTheme.bentoJacket),
          const SizedBox(height: 16),
          Text(
            "Before ${AppConfigScope.of(context)?.appName ?? 'Mockathon'}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You are registered but not currently assigned to an active ${AppConfigScope.of(context)?.appName.toLowerCase() ?? 'mockathon'}.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyAttendedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 30),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            "Already Attended",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You have already attended a ${AppConfigScope.of(context)?.appName.toLowerCase() ?? 'mockathon'}. Thank you for participating!",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksSection(String uid, String branch) {
    return StreamBuilder<bool>(
      stream: _dataService.getResultsPublishedStream(branch: branch),
      builder: (context, settingSnap) {
        if (settingSnap.hasError) {
          return Center(
            child: Text("Error checking results status: ${settingSnap.error}"),
          );
        }

        if (!settingSnap.hasData) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final areResultsPublished = settingSnap.data ?? false;

        if (!areResultsPublished) {
          return Container(
            width: double.infinity,
            height: 180,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.bentoDecoration(
              color: Colors.white,
              radius: 30,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  "Results Pending",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Results will be published shortly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<MarkModel?>(
          stream: _marksStream,
          builder: (context, markSnap) {
            if (markSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final marks = markSnap.data ?? MarkModel();

            return LayoutBuilder(
              builder: (context, constraints) {
                // Determine if we can do Bento layout
                // Using 350 as safe minimum for splitting width
                final bool isTooNarrow = constraints.maxWidth < 350;
                final double gap = 10;
                // Standard height for small cards
                final double smallHeight = 150;
                // Big card height = 2 * small + gap
                final double bigHeight = (smallHeight * 2) + gap;

                if (AppTheme.isMobile(context) || isTooNarrow) {
                  return Column(
                    children: [
                      _buildAptitudeCard(marks),
                      SizedBox(height: gap),
                      _buildTechnicalCard(marks),
                      SizedBox(height: gap),
                      _buildMachineTestCard(marks),
                      SizedBox(height: gap),
                      _buildGdCard(marks),
                      SizedBox(height: gap),
                      _buildHrCard(marks),
                    ],
                  );
                }

                // Bento Grid Layout:
                // [ Aptitude (Big) ]  [ Tech ]
                //                     [ Machine ]
                //
                // [ GD ] [ HR ]
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildAptitudeCard(marks, height: bigHeight),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: smallHeight,
                                  child: _buildTechnicalCard(
                                    marks,
                                    height: smallHeight,
                                  ),
                                ),
                                SizedBox(height: gap),
                                SizedBox(
                                  height: smallHeight,
                                  child: _buildMachineTestCard(
                                    marks,
                                    height: smallHeight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: smallHeight,
                            child: _buildGdCard(marks, height: smallHeight),
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: SizedBox(
                            height: smallHeight,
                            child: _buildHrCard(marks, height: smallHeight),
                          ),
                        ),
                      ],
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

  Widget _buildAptitudeCard(MarkModel marks, {double? height}) {
    return Container(
      height: height,
      constraints: height == null ? const BoxConstraints(minHeight: 150) : null,
      width: double.infinity,
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
                fontSize: 18,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.psychology, size: 48, color: Colors.grey),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aptitude",
                style: TextStyle(
                  fontSize: 16,
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
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 600.ms).scale(curve: Curves.easeOutBack);
  }

  Widget _buildTechnicalCard(MarkModel marks, {double? height}) {
    return Container(
          height: height,
          constraints: height == null ? const BoxConstraints(minHeight: 150) : null,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.code, color: Colors.grey),
                  Text(
                    "${marks.technical.toInt()} / 25",
                    style: TextStyle(
                      color: _getMarkColor(marks.technical * 4),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Technical Round",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    marks.technicalFeedback.isNotEmpty
                        ? marks.technicalFeedback
                        : "No feedback",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fade(delay: 100.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildMachineTestCard(MarkModel marks, {double? height}) {
    return Container(
          height: height,
          constraints: height == null ? const BoxConstraints(minHeight: 150) : null,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.computer, color: Colors.grey),
                  Text(
                    "${marks.machineTest.toInt()} / 25",
                    style: TextStyle(
                      color: _getMarkColor(marks.machineTest * 4),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Machine Test",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    marks.machineTestFeedback.isNotEmpty
                        ? marks.machineTestFeedback
                        : "No feedback",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fade(delay: 200.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildHrCard(MarkModel marks, {double? height}) {
    return Container(
          height: height,
          constraints: height == null ? const BoxConstraints(minHeight: 150) : null,
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
                      Text(
                        "HR Round",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${marks.hr.toInt()} / 25",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (marks.hrFeedback.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    marks.hrFeedback,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fade(delay: 200.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildGdCard(MarkModel marks, {double? height}) {
    return Container(
      height: height,
      constraints: height == null ? const BoxConstraints(minHeight: 150) : null,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    "${marks.gd.toInt()} / 25",
                    style: TextStyle(
                      color: _getMarkColor(marks.gd * 4),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    marks.gdFeedback.isNotEmpty
                        ? marks.gdFeedback
                        : "No feedback",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
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
            color: Colors.white.withValues(alpha: 0.5),
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

  Widget _buildCVSection(BuildContext context, StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 36),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF4A90E2),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resume / CV",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  student.cvUrl != null
                      ? "Resume uploaded"
                      : "No resume uploaded yet",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (student.cvUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => _launchURL(student.cvUrl!),
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                tooltip: "View Resume",
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : () => _uploadResume(student.uid),
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file, size: 20),
            label: Text(
              _isUploading
                  ? "Uploading..."
                  : (student.cvUrl != null ? "Update" : "Upload"),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadResume(String uid) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        setState(() => _isUploading = true);

        final platformFile = result.files.single;

        // Handle bytes - if on web bytes are already there, otherwise read from path
        Uint8List? fileBytes = platformFile.bytes;

        // Removed local file path fallback as it requires dart:io
        // withData: true ensures bytes are available on mobile too.

        if (fileBytes != null) {
          String downloadUrl = await _resumeService.uploadResume(
            fileBytes,
            platformFile.name,
            uid,
          );
          await _resumeService.updateStudentCvUrl(uid, downloadUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Resume uploaded successfully!")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading resume: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch resume URL')),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildHistorySection(StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(color: AppTheme.cardLight, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mockathon History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ...student.mockathonHistory.map((historyId) {
            return StreamBuilder<MarkModel?>(
              stream: _dataService.getMarks(
                student.uid,
                mockathonId: historyId,
              ),
              builder: (context, marksSnap) {
                if (marksSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final marks = marksSnap.data;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.bentoDecoration(
                    color: Colors.white,
                    radius: 16,
                    shadow: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Session ID: ${historyId.length > 8 ? historyId.substring(0, 8) : historyId}...",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.bentoAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Completed",
                              style: TextStyle(color: AppTheme.bentoAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (marks != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (marks.aptitude > 0)
                              _buildStatCard("Aptitude", "${marks.aptitude}", Colors.blue),
                            if (marks.machineTest > 0)
                              _buildStatCard("Machine", "${marks.machineTest}", Colors.orange),
                            if (marks.technical > 0)
                              _buildStatCard("Technical", "${marks.technical}", Colors.green),
                            if (marks.gd > 0)
                              _buildStatCard("GD", "${marks.gd}", Colors.purple),
                            if (marks.hr > 0)
                              _buildStatCard("HR", "${marks.hr}", Colors.red),
                          ],
                        ),
                        if (marks.hrFeedback.isNotEmpty || marks.technicalFeedback.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text("Feedback:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          if (marks.hrFeedback.isNotEmpty)
                            Text("HR: ${marks.hrFeedback}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          if (marks.technicalFeedback.isNotEmpty)
                            Text("Technical: ${marks.technicalFeedback}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text("No marks recorded for this session.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
