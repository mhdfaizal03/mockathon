import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewer/NavbarHome/aptitude_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/gd_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/hr_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/technical_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/machine_test_mark_page.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/resume_service.dart';

class NavbarHome extends StatefulWidget {
  final String studentId;
  final String studentName;

  const NavbarHome({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<NavbarHome> createState() => _NavbarHomeState();
}

class _NavbarHomeState extends State<NavbarHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TechnicalMarkPage(studentId: widget.studentId),
      MachineTestMarkPage(studentId: widget.studentId),
      HrMarkPage(studentId: widget.studentId),
      AptitudeMarkPage(studentId: widget.studentId),
      GdMarkPage(studentId: widget.studentId),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.warmBackgroundGradient,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLargeDoc = constraints.maxWidth > 900;

            if (isLargeDoc) {
              return Row(
                children: [
                  // Desktop Sidebar Panel
                  _buildSidebar(context),
                  // Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(isLargeDoc),
                        Expanded(child: pages[_currentIndex]),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Mobile View
            return Column(
              children: [
                _buildHeader(isLargeDoc),
                Expanded(child: pages[_currentIndex]),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 900
          ? null
          : _buildMobileNavbar(),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(
        color: const Color(0xFFEFEBE4),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Image.asset('assets/Mockuplogo.png', height: 45),
              const SizedBox(width: 10),
              const Text('MOCKATHON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 30),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search here',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 24),
          // Main Nav Grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _buildSidebarItem(0, Icons.code, "Technical Round"),
                      _buildSidebarItem(1, Icons.computer, "Machine Test"),
                      _buildSidebarItem(2, Icons.person_search, "HR Round"),
                      _buildSidebarItem(3, Icons.psychology, "Aptitude"),
                      _buildSidebarItem(4, Icons.groups, "Group Disc."),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Profile Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF232323), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.amber, radius: 18),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Interviewer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('User', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF232323) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavbar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppTheme.bentoDecoration(
        color: Colors.white,
        radius: 16,
        shadow: true,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.bentoJacket,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Tech'),
            BottomNavigationBarItem(
              icon: Icon(Icons.computer),
              label: 'Machine',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search),
              label: 'HR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Aptitude',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'GD'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLarge) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: isLarge ? 0 : 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 24 : 12,
        vertical: isLarge ? 12 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Home / Students / Assessment', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text(
                    'Assessment Mode',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                  ),
                  Text(
                    "Candidate: ${widget.studentName}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              StreamBuilder<StudentModel>(
                stream: DataService().getStudent(widget.studentId),
                builder: (context, snapshot) {
                  final student = snapshot.data;
                  final hasCv = student?.cvUrl != null;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!hasCv) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Candidate hasn't uploaded a resume yet",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          return;
                        }

                        ResumeService().downloadResume(student!.cvUrl!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCv
                            ? AppTheme.bentoJacket
                            : Colors.grey.withValues(alpha: 0.2),
                        foregroundColor: hasCv ? Colors.white : Colors.grey,
                        elevation: hasCv ? 2 : 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: hasCv ? Colors.white : Colors.grey,
                      ),
                      label: const Text("Resume"),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 20), 
                onPressed: () {},
                color: Colors.black54,
              ),
              IconButton(
                icon: const Icon(Icons.ios_share, size: 20), 
                onPressed: () {},
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
