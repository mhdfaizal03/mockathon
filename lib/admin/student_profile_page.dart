import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentProfilePage extends StatelessWidget {
  final StudentModel student;

  const StudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final DataService dataService = DataService();

    return Scaffold(
      backgroundColor: AppTheme.bentoBg,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                      const Text(
                        "Candidate Assessment Profile",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Hero Section (Profile + Basic Info)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.bentoDecoration(
                      color: AppTheme.bentoJacket,
                      radius: 40,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.bentoJacket,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    student.email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _badge(student.stack, Colors.white24),
                                      const SizedBox(width: 8),
                                      _badge(
                                        student.remainStatus,
                                        Colors.white24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),

                  // Marks Section
                  // Marks Section
                  StreamBuilder<bool>(
                    stream: dataService.getResultsPublishedStream(),
                    builder: (context, pubSnap) {
                      final isPublished = pubSnap.data ?? false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isPublished)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Internal View • Results are hidden from student",
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          StreamBuilder<MarkModel?>(
                            stream: dataService.getMarks(student.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final marks = snapshot.data ?? MarkModel();

                              return Column(
                                children: [
                                  // Marks Summary Cards
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isMobile =
                                          constraints.maxWidth < 700;
                                      List<Widget> cards = [
                                        Expanded(
                                          flex: isMobile ? 0 : 1,
                                          child: _buildMarkCard(
                                            "Aptitude",
                                            marks.aptitude,
                                            Icons.psychology,
                                            Colors.blueAccent,
                                            max: 25,
                                          ),
                                        ),
                                        SizedBox(
                                          width: isMobile ? 0 : 16,
                                          height: isMobile ? 16 : 0,
                                        ),
                                        Expanded(
                                          flex: isMobile ? 0 : 1,
                                          child: _buildMarkCard(
                                            "Group Discussion",
                                            marks.gd,
                                            Icons.groups,
                                            Colors.purpleAccent,
                                            max: 25,
                                          ),
                                        ),
                                        SizedBox(
                                          width: isMobile ? 0 : 16,
                                          height: isMobile ? 16 : 0,
                                        ),
                                        Expanded(
                                          flex: isMobile ? 0 : 1,
                                          child: _buildMarkCard(
                                            "Technical / HR",
                                            marks.hr,
                                            Icons.person_search,
                                            Colors.orangeAccent,
                                            max: 25,
                                          ),
                                        ),
                                      ];

                                      if (isMobile) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: cards,
                                        );
                                      }
                                      return Row(children: cards);
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Detailed Feedback Section (if needed) or just display it in cards?
                                  // For now, let's just keep the cards comprehensive. But if we want feedback shown:
                                  if (marks.aptitudeFeedback.isNotEmpty ||
                                      marks.gdFeedback.isNotEmpty ||
                                      marks.hrFeedback.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      width: double.infinity,
                                      decoration: AppTheme.bentoDecoration(
                                        color: Colors.white,
                                        radius: 32,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Interviewer Feedback",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (marks.aptitudeFeedback.isNotEmpty)
                                            _buildFeedbackItem(
                                              "Aptitude",
                                              marks.aptitudeFeedback,
                                            ),
                                          if (marks.gdFeedback.isNotEmpty)
                                            _buildFeedbackItem(
                                              "GD",
                                              marks.gdFeedback,
                                            ),
                                          if (marks.hrFeedback.isNotEmpty)
                                            _buildFeedbackItem(
                                              "HR",
                                              marks.hrFeedback,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ].animate(interval: 100.ms).fade().slideX(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMarkCard(
    String title,
    double score,
    IconData icon,
    Color accent, {
    double max = 100,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              Text(
                "${score.toInt()}/${max.toInt()}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score, max: max),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / max,
            backgroundColor: Colors.grey[100],
            color: _getScoreColor(score, max: max),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(String module, String feedback) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(feedback, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score, {double max = 100}) {
    final percentage = score / max;
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.5) return Colors.orange;
    if (percentage >= 0.4) return Colors.amber;
    return Colors.redAccent;
  }
}
