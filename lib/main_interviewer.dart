import 'package:flutter/material.dart';
import 'package:mockathon/interviewer/interviewer_nav_screen.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:mockathon/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// INTERVIEWER ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Notification Init Error: $e");
  }

  runApp(const ProviderScope(child: InterviewerApp()));
}

class InterviewerApp extends StatelessWidget {
  const InterviewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockathon Interviewer',
      theme: AppTheme.lightTheme,
      home: const InterviewerAuthWrapper(),
    );
  }
}

class InterviewerAuthWrapper extends StatelessWidget {
  const InterviewerAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return StreamBuilder<UserModel?>(
            stream: AuthService().getUserProfileStream(snapshot.data!.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnap.data != null) {
                final userProfile = roleSnap.data!;
                if (userProfile.role == UserRole.interviewer) {
                  return const InterviewerNavScreen();
                } else {
                  return _buildAccessDenied(context);
                }
              }
              return const LoginPage(userType: "Interviewer");
            },
          );
        }

        return const LoginPage(userType: "Interviewer");
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_bad, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Wrong Portal",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("This portal is for Interviewers only."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
