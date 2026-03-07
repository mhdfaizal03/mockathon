import 'package:flutter/material.dart';
import 'package:mockathon/admin/dashboard.dart';
import 'package:mockathon/authentication/welcome_page.dart';
import 'package:mockathon/core/splash_screen.dart';
import 'package:mockathon/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/interviewee/nav_screen.dart';
import 'package:mockathon/interviewer/interviewer_nav_screen.dart';
import 'package:mockathon/interviewee/onboarding_screen.dart';
import 'package:mockathon/core/supabase_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockathon',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
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
