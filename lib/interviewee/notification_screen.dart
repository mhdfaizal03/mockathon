import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  final String userRole;
  const NotificationScreen({super.key, this.userRole = 'interviewee'});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final double horizontalPadding = isMobile ? 16 : 24;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "Notifications",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: StreamBuilder<List<NotificationModel>>(
                        stream: _dataService.getNotifications(widget.userRole),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No notifications yet",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          final notifications = snapshot.data!;
                          final uid = FirebaseAuth.instance.currentUser?.uid;

                          return StreamBuilder<MarkModel?>(
                            stream: uid != null
                                ? _dataService.getMarks(uid)
                                : Stream.value(null),
                            builder: (context, markSnapshot) {
                              final marks = markSnapshot.data;
                              final double totalMarks = marks != null
                                  ? (marks.aptitude + marks.gd + marks.hr)
                                  : 0.0;

                              final filteredNotifications = notifications.where((
                                n,
                              ) {
                                if (n.minMarks != null) {
                                  // If user has no marks or total is less than minMarks, hide it
                                  if (totalMarks < n.minMarks!) return false;
                                }
                                return true;
                              }).toList();

                              if (filteredNotifications.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_off_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No relevant notifications",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                itemCount: filteredNotifications.length,
                                separatorBuilder: (c, i) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final notif = filteredNotifications[index];
                                  // Format timestamp
                                  final timeAgo = DateTime.now()
                                      .difference(notif.timestamp)
                                      .inMinutes;

                                  return Container(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    decoration: AppTheme.bentoDecoration(
                                      color: Colors.white,
                                      radius: 24,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.bentoJacket
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.campaign,
                                            color: AppTheme.bentoJacket,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notif.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "${timeAgo}m ago",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notif.message,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80), // Space for Nav Bar
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
