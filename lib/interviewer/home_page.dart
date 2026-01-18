import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/interviewer/navbar_home.dart';
import 'package:mockathon/authentication/welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLarge = constraints.maxWidth > 900;

          return SafeArea(
            child: Column(
              children: [
                // 1. Header (Pill Style) - Only on Mobile
                if (!isLarge) _buildHeader(),

                // 2. Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Search Bar Pill
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Search students...",
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Student List/Grid
                            StreamBuilder<List<StudentModel>>(
                              stream: _dataService.getStudents(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final students = snapshot.data!.where((s) {
                                  return s.name.toLowerCase().contains(
                                        _searchQuery,
                                      ) ||
                                      s.stack.toLowerCase().contains(
                                        _searchQuery,
                                      );
                                }).toList();

                                if (students.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 40),
                                    child: Text(
                                      "No students found",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                }

                                // If constrained width is small (e.g. < 600), use ListView.
                                bool isMobile = constraints.maxWidth < 600;

                                if (isMobile) {
                                  return ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: students.length,
                                    separatorBuilder: (c, i) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      return _buildBentoStudentListTile(
                                        students[index],
                                        index,
                                      );
                                    },
                                  );
                                } else {
                                  return GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 400,
                                          childAspectRatio: 1.5,
                                          crossAxisSpacing: 24,
                                          mainAxisSpacing: 24,
                                        ),
                                    itemCount: students.length,
                                    itemBuilder: (context, index) {
                                      return _buildBentoStudentCard(
                                        students[index],
                                        index,
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Interviewer",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          InkWell(
            onTap: () => _confirmLogout(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bentoBg,
              ),
              child: const Icon(Icons.logout, size: 20, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }

  // Mobile List View Tile
  Widget _buildBentoStudentListTile(StudentModel student, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NavbarHome(studentId: student.uid, studentName: student.name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.bentoBg,
              child: Text(
                student.name[0],
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    student.stack,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bentoJacket.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                student.randomId,
                style: const TextStyle(
                  color: AppTheme.bentoJacket,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop/Tablet Grid Card
  Widget _buildBentoStudentCard(StudentModel student, int index) {
    // Standard Card Style (Uniform)
    const Color bgColor = AppTheme.bentoSurface;
    const Color textColor = Colors.black87;
    const Color subTextColor = Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NavbarHome(studentId: student.uid, studentName: student.name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.bentoDecoration(color: bgColor, radius: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.bentoBg,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_outward, color: subTextColor, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  student.stack,
                  style: const TextStyle(color: subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bentoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.randomId,
                    style: const TextStyle(color: textColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
