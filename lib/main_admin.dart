import 'package:flutter/material.dart';
import 'package:mockathon/admin/dashboard.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:mockathon/core/supabase_config.dart';
import 'package:mockathon/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:mockathon/core/splash_screen.dart';

// ADMIN ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockathon Admin',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(target: AdminAuthWrapper()),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

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
          // User is logged in, check if Admin
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
                if (userProfile.role == UserRole.admin) {
                  return const Dashboard();
                } else {
                  return _buildAccessDenied(context);
                }
              }

              // No profile found
              return const LoginPage(userType: "Admin");
            },
          );
        }

        // Not logged in -> Admin Login Page (No Welcome Page)
        return const LoginPage(userType: "Admin");
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_bad, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Access Denied",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("You are logged in, but not as an Admin."),
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
