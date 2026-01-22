import 'package:flutter/material.dart';

class AddInterns extends StatefulWidget {
  const AddInterns({super.key});

  @override
  State<AddInterns> createState() => _AddInternsState();
}

class _AddInternsState extends State<AddInterns> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stackController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Theme Constants
  static const Color bgDark = Color(0xFF1E1E2C);
  static const Color accentPurple = Color(0xFFBB86FC);

  void _saveIntern() {
    if (_formKey.currentState!.validate()) {
      final internData = {
        "name": _nameController.text.trim(),
        "stack": _stackController.text.trim(),
        "experience": _experienceController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
      };

      debugPrint("Intern Added: $internData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Intern added successfully"),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stackController.dispose();
    _experienceController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentPurple),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: isDesktop ? 500 : double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "New Intern Details",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: accentPurple.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      /// Name
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          "Full Name",
                          Icons.person_outline,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Name is required"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      /// Stack
                      TextFormField(
                        controller: _stackController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          "Tech Stack",
                          Icons.code_rounded,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Stack is required"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      /// Experience
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          "Experience (Years)",
                          Icons.work_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Experience is required";
                          }
                          if (double.tryParse(value) == null) {
                            return "Enter a valid number";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      /// Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          "Email Address",
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      /// Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          "Phone Number",
                          Icons.phone_outlined,
                        ),
                        validator: (value) => value == null || value.length < 10
                            ? "Enter valid phone number"
                            : null,
                      ),

                      const SizedBox(height: 32),

                      /// Save Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFFF5722)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF5722,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveIntern,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Add Intern",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
