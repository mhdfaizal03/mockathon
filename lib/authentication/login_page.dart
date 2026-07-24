import 'package:flutter/material.dart';

import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/authentication/register_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/core/theme.dart';

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
    final isMobile = AppTheme.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Clean, minimalist background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/Mockuplogo.png', height: 72)
                    .animate().fade(duration: 500.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 32),

                Text(
                  "${widget.userType} Portal",
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ).animate().fade(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  isAdmin ? "Sign in to access admin dashboard" : "Welcome back. Please enter your details.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ).animate().fade(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 40),

                // Form Container
                Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Email"),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDecoration("Enter your email"),
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                              ? "Enter a valid email"
                              : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel("Password"),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDecoration("Enter your password").copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF999999),
                                size: 20,
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF9BA15), // Yellow Theme
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black87,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Sign in",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        if (isInterviewee) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF111111),
                              ),
                              child: const Text(
                                "Don't have an account? Sign up",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fade(delay: 300.ms, duration: 500.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 40),
                Image.asset(
                  "assets/softlogo.png",
                  height: 70,
                ).animate().fade(delay: 450.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Reset Password"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter your email address to receive a password reset link.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                      ),
                      validator: (value) => (value == null || !value.contains('@')) ? "Enter a valid email" : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9BA15),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isResetting = true);
                            try {
                              await _authService.sendPasswordResetEmail(emailController.text.trim());
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Password reset email sent!"), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              setState(() => isResetting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isResetting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Send Link"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF9BA15), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
