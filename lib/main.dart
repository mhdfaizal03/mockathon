import 'package:flutter/material.dart';
import 'package:mockathon/admin/dashboard.dart';
import 'package:mockathon/authentication/welcome_page.dart';
import 'package:mockathon/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/interviewee/nav_screen.dart';
import 'package:mockathon/interviewer/interviewer_nav_screen.dart';
import 'package:mockathon/interviewee/onboarding_screen.dart';
import 'package:mockathon/services/notification_service.dart'; // Added import
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added import for ProviderScope
import 'package:flutter/foundation.dart'; // Added import for debugPrint

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notifications
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Notification Init Error: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  // Renamed from MockathonApp
  const MyApp({super.key}); // Renamed from MockathonApp

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockathon',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
                if (userProfile.role == UserRole.admin) {
                  return const Dashboard();
                }
                if (userProfile.role == UserRole.interviewer) {
                  return const InterviewerNavScreen();
                }

                if (!userProfile.hasCompletedOnboarding) {
                  return const OnboardingScreen();
                }
                return const NavScreen();
              }

              return const WelcomePage();
            },
          );
        }

        return const WelcomePage();
      },
    );
  }
}
