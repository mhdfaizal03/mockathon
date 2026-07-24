import 'package:flutter/material.dart';

import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedStack;
  String? _selectedRemainStatus;
  String? _selectedBranch;
  bool _isLoading = false;

  final List<String> _stackOptions = [
    'UI/UX',
    'Flutter',
    'Python',
    'MERN',
    'Digital Marketing',
    'Data Analytics',
    'Data Science',
  ];

  final List<String> _remainStatusOptions = ['Main Project', 'Mini Project'];
  final List<String> _branchOptions = [
    'Kozhikode',
    'Palakkad',
    'Perinthalmanna',
    'Kochi',
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final activeMockathonId = await DataService().getActiveMockathonIdStream(branch: _selectedBranch!).first;

        await _authService.registerStudent(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _selectedStack!,
          _selectedRemainStatus!,
          _selectedBranch!,
          mockathonId: activeMockathonId,
        );

        // Auto-login after registration or updating existing user
        try {
          await _authService.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } catch (loginError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email registered, but incorrect password. Please login."),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Clean minimalist background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset('assets/Mockuplogo.png', height: 72)
                            .animate().fade(duration: 500.ms).scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutCubic,
                                ),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          "Candidate Registration",
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ).animate().fade(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                      ),
                      const SizedBox(height: 32),

                      _buildTextField(
                        _nameController,
                        "Full Name",
                        "Enter your full name",
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        _emailController,
                        "Email",
                        "Enter your email",
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        "Tech Stack",
                        _stackOptions,
                        _selectedStack,
                        (val) => setState(() => _selectedStack = val),
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        "Branch",
                        _branchOptions,
                        _selectedBranch,
                        (val) => setState(() => _selectedBranch = val),
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        "Remain Status",
                        _remainStatusOptions,
                        _selectedRemainStatus,
                        (val) => setState(() => _selectedRemainStatus = val),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        _passwordController,
                        "Password",
                        "Create a password",
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        _confirmPasswordController,
                        "Confirm Password",
                        "Confirm your password",
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (val != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

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
                          onPressed: _isLoading ? null : _register,
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
                                  "Create Account",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isPassword = false,
    bool isEmail = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: const TextStyle(fontSize: 15),
          decoration: _inputDecoration(hint),
          validator: validator ?? (v) {
            if (v == null || v.isEmpty) return "Required";
            if (isEmail && !v.contains("@")) return "Invalid Email";
            if (isPassword && v.length < 6) return "Min 6 chars";
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF999999)),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 15)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: _inputDecoration("Select $label"),
          validator: (v) => v == null ? "Required" : null,
          isExpanded: true,
        ),
      ],
    );
  }
}
