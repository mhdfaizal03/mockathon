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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MockathonApp());
}

class MockathonApp extends StatelessWidget {
  const MockathonApp({super.key});

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
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserProfile(snapshot.data!.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnap.data != null) {
                final role = roleSnap.data!.role;
                if (role == UserRole.admin) return const Dashboard();
                if (role == UserRole.interviewer)
                  return const InterviewerNavScreen();
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
