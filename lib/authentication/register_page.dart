import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';

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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.registerStudent(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _selectedStack!,
          _selectedRemainStatus!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created! User generated random ID."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to login
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset("assets/softlogo.png", height: 100),
      ),
      backgroundColor: AppTheme.bentoBg, // Bento Background
      appBar: AppBar(
        title: Text(
          "Student Registration",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.bentoDecoration(
              color: Colors.white,
              radius: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    padding: const EdgeInsets.all(0),
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
                  const SizedBox(height: 24),

                  Text(
                    "Join as Interviewee",
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(_nameController, "Full Name", Icons.person),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _emailController,
                    "Email",
                    Icons.email,
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    "Tech Stack",
                    Icons.code,
                    _stackOptions,
                    _selectedStack,
                    (val) => setState(() => _selectedStack = val),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    "Remain Status",
                    Icons.assignment,
                    _remainStatusOptions,
                    _selectedRemainStatus,
                    (val) => setState(() => _selectedRemainStatus = val),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _passwordController,
                    "Password",
                    Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _confirmPasswordController,
                    "Confirm Password",
                    Icons.lock,
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
                        backgroundColor: AppTheme.bentoJacket,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "REGISTER",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
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
      validator:
          validator ??
          (v) {
            if (v == null || v.isEmpty) return "Required";
            if (isEmail && !v.contains("@")) return "Invalid Email";
            if (isPassword && v.length < 6) return "Min 6 chars";
            return null;
          },
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
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
      validator: (v) => v == null ? "Required" : null,
      isExpanded: true,
    );
  }
}
