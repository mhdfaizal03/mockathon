import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/authentication/welcome_page.dart';
import 'package:mockathon/interviewee/profile_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dashboard Content
    final List<Widget> pages = [
      _buildAssessmentOverview(theme),
      _buildUserManagement('interviewee', theme),
      _buildUserManagement('interviewer', theme),
      _buildBroadcastScreen(theme),
      _buildPublishScreen(theme),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bentoBg, // Bento Background
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side Navigation (Bento Style)
            if (MediaQuery.of(context).size.width > 800) _buildSideNav(theme),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. Header (Pill Style)
                    _buildHeader(theme),

                    // 2. Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: pages[_selectedIndex],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: MediaQuery.of(context).size.width <= 800
          ? _buildDrawer(theme)
          : null,
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width <= 800)
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
              const Text(
                "Admin Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _confirmLogout(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardLight,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.logout,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(ThemeData theme) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 32,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "MOCKATHON",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppTheme.bentoJacket,
            ),
          ),
          const SizedBox(height: 48),
          _navItem(0, Icons.dashboard, "Overview", theme),
          const SizedBox(height: 12),
          _navItem(1, Icons.people, "Students", theme),
          const SizedBox(height: 12),
          _navItem(2, Icons.work, "Interviewers", theme),
          const SizedBox(height: 12),
          _navItem(3, Icons.campaign, "Broadcast", theme),
          const SizedBox(height: 12),
          _navItem(4, Icons.publish, "Publish Result", theme),
          const Spacer(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: AppTheme.bentoBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: AppTheme.bentoDecoration(
                color: AppTheme.bentoJacket,
                radius: 24,
              ),
              child: const Text(
                "MOCKATHON",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _navItem(0, Icons.dashboard, "Overview", theme),
            const SizedBox(height: 12),
            _navItem(1, Icons.people, "Students", theme),
            const SizedBox(height: 12),
            _navItem(2, Icons.work, "Interviewers", theme),
            const SizedBox(height: 12),
            _navItem(3, Icons.campaign, "Broadcast", theme),
            const SizedBox(height: 12),
            _navItem(4, Icons.publish, "Publish Result", theme),
            const Spacer(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String title, ThemeData theme) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (Scaffold.of(context).hasDrawer &&
            Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: AppTheme.bentoDecoration(
          color: isSelected ? AppTheme.bentoJacket : Colors.transparent,
          radius: 24,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentOverview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of Bento Stats
        StreamBuilder<List<StudentModel>>(
          stream: _dataService.getStudents(),
          builder: (context, snapshot) {
            int total = 0;
            if (snapshot.hasData) total = snapshot.data!.length;

            return Row(
              children: [
                Expanded(
                  child: _bentoStatCard(
                    "Students",
                    "$total",
                    AppTheme.bentoJacket,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bentoStatCard(
                    "Sessions",
                    "Active",
                    AppTheme.bentoSurface,
                    Colors.black87,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        const SizedBox(height: 24),

        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.bentoDecoration(
            color: AppTheme.bentoSurface,
            radius: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Assessment Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<StudentModel>>(
                  stream: _dataService.getStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const Center(child: Text("No data found"));

                    final students = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return StreamBuilder<MarkModel?>(
                          stream: _dataService.getMarks(student.uid),
                          builder: (context, markSnap) {
                            final marks = markSnap.data;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProfilePage(student: student),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: AppTheme.bentoDecoration(
                                    color: AppTheme.softWhite,
                                    radius: 20,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.bentoBg,
                                        child: Text(
                                          student.name[0],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              student.randomId,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _miniBadge("APT", marks?.aptitude ?? 0),
                                      const SizedBox(width: 8),
                                      _miniBadge("GD", marks?.gd ?? 0),
                                      const SizedBox(width: 8),
                                      _miniBadge("HR", marks?.hr ?? 0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _bentoStatCard(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(color: bg, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
          Text(label, style: TextStyle(color: text.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, double score) {
    final color = score > 0 ? AppTheme.bentoJacket : Colors.grey[300];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$label: ${score.toInt()}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserManagement(String role, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header in a bento tile? Or just text. Let's do a bento tile header.
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoAccent,
                  radius: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == 'interviewee' ? "Students" : "Interviewers",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      "Management",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            if (role == 'interviewer' || role == 'interviewee') ...[
              const SizedBox(width: 16),
              InkWell(
                onTap: () => role == 'interviewer'
                    ? _showAddStaffDialog(role)
                    : _showAddStudentDialog(),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.bentoDecoration(
                    color: AppTheme.bentoSurface,
                    radius: 32,
                  ),
                  child: const Icon(Icons.add, size: 32),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Container(
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.bentoDecoration(
            color: AppTheme.bentoSurface,
            radius: 32,
          ),
          child: StreamBuilder<List<UserModel>>(
            stream: _dataService.getUsersByRole(role),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final users = snapshot.data ?? [];

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: user is StudentModel
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(student: user),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.bentoDecoration(
                          color: AppTheme.softWhite,
                          radius: 20,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.bentoBg,
                              child: Icon(
                                user is StudentModel
                                    ? Icons.person
                                    : Icons.badge,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty
                                        ? user.name
                                        : (user is StudentModel
                                              ? "Student"
                                              : user.role.name[0]
                                                        .toUpperCase() +
                                                    user.role.name.substring(
                                                      1,
                                                    )),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: Colors.blue[300],
                                size: 20,
                              ),
                              onPressed: () => _showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                                size: 20,
                              ),
                              onPressed: () =>
                                  _showDeleteConfirmation(user.uid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  void _showAddStudentDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    final stackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Add New Student",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stackController,
                decoration: InputDecoration(
                  labelText: "Stack / Discipline",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bentoJacket,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await _authService.registerStudent(
                  emailController.text,
                  passController.text,
                  nameController.text,
                  stackController.text,
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                // handle error
              }
            },
            child: const Text("ADD", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(String role) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Add New $role",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                filled: true,
                fillColor: AppTheme.bentoBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                filled: true,
                fillColor: AppTheme.bentoBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              decoration: InputDecoration(
                labelText: "Password",
                filled: true,
                fillColor: AppTheme.bentoBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bentoJacket,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await _authService.registerStaff(
                  emailController.text,
                  passController.text,
                  nameController.text,
                  role == 'interviewer' ? UserRole.interviewer : UserRole.admin,
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                // handle error
              }
            },
            child: const Text("ADD", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final stackController = TextEditingController(
      text: user is StudentModel ? user.stack : "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit User Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (user is StudentModel) ...[
                TextField(
                  controller: stackController,
                  decoration: InputDecoration(
                    labelText: "Stack / Discipline",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bentoJacket,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              UserModel updatedUser;
              if (user is StudentModel) {
                updatedUser = StudentModel(
                  uid: user.uid,
                  email: user.email,
                  name: nameController.text,
                  stack: stackController.text,
                  randomId: user.randomId,
                  notifications: user.notifications,
                );
              } else {
                updatedUser = UserModel(
                  uid: user.uid,
                  email: user.email,
                  name: nameController.text,
                  role: user.role,
                );
              }
              await _dataService.updateUser(updatedUser);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String uid) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete User?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this user? This action cannot be undone.",
        ),
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
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.deleteUser(uid);
    }
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

  Widget _buildBroadcastScreen(ThemeData theme) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetRole = 'all';

    final presets = [
      {
        "title": "Next Round Alert",
        "msg": "Heading to next round, prepare for it!",
        "icon": Icons.trending_up,
        "color": Colors.orangeAccent,
      },
      {
        "title": "Welcome",
        "msg": "Welcome to Mockathon! Please check your schedule.",
        "icon": Icons.handshake_outlined,
        "color": Colors.blueAccent,
      },
      {
        "title": "Break Time",
        "msg": "Short break for 15 mins. Please be back on time.",
        "icon": Icons.coffee_outlined,
        "color": Colors.brown,
      },
      {
        "title": "Results Out",
        "msg": "Results are published. Check your dashboard.",
        "icon": Icons.assignment_turned_in_outlined,
        "color": Colors.green,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.bentoDecoration(
              color: AppTheme.bentoJacket,
              radius: 32,
            ),
            child: const Row(
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Global Broadcast",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Send instant alerts to users",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Quick Presets",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final p = presets[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      titleController.text = p['title'] as String;
                      messageController.text = p['msg'] as String;
                    },
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.bentoDecoration(
                        color: (p['color'] as Color).withOpacity(0.1),
                        radius: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            p['icon'] as IconData,
                            color: p['color'] as Color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: p['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.bentoDecoration(
              color: AppTheme.bentoSurface,
              radius: 32,
            ),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Notification Title",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Message Body",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return DropdownButtonFormField<String>(
                      value: targetRole,
                      decoration: InputDecoration(
                        labelText: "Target Users",
                        filled: true,
                        fillColor: AppTheme.bentoBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text("All Users"),
                        ),
                        DropdownMenuItem(
                          value: 'interviewee',
                          child: Text("All Students"),
                        ),
                        DropdownMenuItem(
                          value: 'interviewer',
                          child: Text("All Interviewers"),
                        ),
                      ],
                      onChanged: (val) =>
                          setInnerState(() => targetRole = val!),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bentoJacket,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (titleController.text.isEmpty ||
                          messageController.text.isEmpty)
                        return;
                      await _dataService.broadcastNotification(
                        NotificationModel(
                          id: '',
                          title: titleController.text,
                          message: messageController.text,
                          timestamp: DateTime.now(),
                          targetRole: targetRole,
                        ),
                      );
                      titleController.clear();
                      messageController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Broadcast Sent!")),
                      );
                    },
                    child: const Text(
                      "SEND BROADCAST",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.bentoDecoration(
              color: AppTheme.bentoAccent,
              radius: 40,
            ),
            child: Column(
              children: [
                const Icon(Icons.publish, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Results Visibility",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Control when students can view their final assessment marks.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                StreamBuilder<bool>(
                  stream: _dataService.getResultsPublishedStream(),
                  builder: (context, snapshot) {
                    final isPublished = snapshot.data ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPublished ? "STATUS: LIVE" : "STATUS: RESTRICTED",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                          Switch(
                            value: isPublished,
                            activeColor: Colors.greenAccent,
                            onChanged: (val) => _confirmPublishResults(val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.bentoDecoration(
              color: AppTheme.bentoSurface,
              radius: 32,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Guidelines",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                BulletItem("Ensure all interviewers have submitted marks."),
                BulletItem("Unpublishing will hide results immediately."),
                BulletItem("Students will receive a notification if enabled."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPublishResults(bool value) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          value ? "Publish Results?" : "Hide Results?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          value
              ? "This will make marks visible to all students immediately."
              : "This will hide marks from all students.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bentoJacket,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.updateResultsPublished(value);
    }
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.bentoJacket,
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
