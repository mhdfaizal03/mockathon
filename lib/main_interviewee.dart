import 'package:flutter/material.dart';
import 'package:mockathon/core/supabase_config.dart';
import 'package:mockathon/interviewee/nav_screen.dart';
import 'package:mockathon/interviewee/onboarding_screen.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:mockathon/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:mockathon/core/splash_screen.dart';

// INTERVIEWEE (STUDENT) ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: IntervieweeApp()));
}

class IntervieweeApp extends StatelessWidget {
  const IntervieweeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockathon Student',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(target: IntervieweeAuthWrapper()),
    );
  }
}

class IntervieweeAuthWrapper extends StatelessWidget {
  const IntervieweeAuthWrapper({super.key});

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

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Authentication Error: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return StreamBuilder<UserModel?>(
            stream: AuthService().getUserProfileStream(snapshot.data!.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnap.hasError) {
                return Scaffold(
                  body: Center(
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
                          Text("Error loading profile: ${roleSnap.error}"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => AuthService().signOut(),
                            child: const Text("Sign Out & Retry"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (roleSnap.hasData && roleSnap.data != null) {
                final userProfile = roleSnap.data!;
                if (userProfile.role == UserRole.interviewee) {
                  if (!userProfile.hasCompletedOnboarding) {
                    return const OnboardingScreen();
                  }
                  return const NavScreen();
                } else {
                  return _buildAccessDenied(context);
                }
              }

              // Profile exists in Auth but not in Firestore (yet?)
              return const LoginPage(userType: "Interviewee");
            },
          );
        }

        // Not logged in
        return const LoginPage(userType: "Interviewee");
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Student Portal",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("Only students can access this area."),
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
