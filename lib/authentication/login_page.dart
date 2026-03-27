import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/authentication/register_page.dart';

class LoginPage extends StatefulWidget {
  final String userType;
  const LoginPage({super.key, this.userType = "User"});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null && mounted) {
          // Strict Role Verification
          bool roleMismatch = false;
          if (widget.userType == "Admin" && user.role != UserRole.admin) {
            roleMismatch = true;
          }
          if (widget.userType == "Interviewer" &&
              user.role != UserRole.interviewer) {
            roleMismatch = true;
          }
          if ((widget.userType == "Interviewee" ||
                  widget.userType == "Candidate") &&
              user.role != UserRole.interviewee) {
            // Corrected the line here
            roleMismatch = true;
          }

          if (roleMismatch) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Access Denied: This account is not authorized as ${widget.userType}",
                ),
                backgroundColor: Colors.red,
              ),
            );
            await _authService.signOut();
            setState(() => _isLoading = false);
            return;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Welcome back, ${user.email}"),
                backgroundColor: Colors.green,
              ),
            );

            // If this page was pushed (e.g. from WelcomePage), pop it to reveal the AuthWrapper's new state
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
          // Navigation is now handled automatically by AuthWrappers in main_*.dart
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login failed: Incorrect email or password."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = widget.userType == "Admin";
    final isInterviewee =
        widget.userType == "Interviewee" || widget.userType == "Candidate";

    return Scaffold(
      backgroundColor: AppTheme.bentoBg, // Bento Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                height: 150,
                width: 150,
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.lightGradient, // Professional Gradient
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset("assets/Mockuplogo.png"),
              ),
              const SizedBox(height: 10),

              Text(
                "${widget.userType} Login",
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin ? "Secure Admin Access" : "Sign in to continue",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Form Container (Bento Style)
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoSurface,
                  radius: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            (value == null || !value.contains('@'))
                            ? "Enter a valid email"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.length < 6)
                            ? "Password must be 6+ chars"
                            : null,
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.bentoJacket,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "LOGIN",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      if (isInterviewee) ...[
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Create Candidate Account",
                            style: TextStyle(
                              color: AppTheme.bentoJacket,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset("assets/softlogo.png", height: 100),
      ),
    );
  }
}
