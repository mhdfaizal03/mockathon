import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/models/user_models.dart';
import 'dart:convert';
import 'dart:html'
    if (dart.library.io) 'package:mockathon/core/web_stub.dart'
    as html;

import 'package:mockathon/admin/student_profile_page.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  static int _selectedIndex = 0;

  // Filtering
  String _selectedStackFilter = 'All';
  String _selectedRemainStatusFilter = 'All';
  String _selectedMarkFilter = 'All'; // New Mark Filter
  String _searchQuery = ''; // New Search Query
  String _selectedSortOption = 'Name A-Z';
  final List<String> _sortOptions = [
    'Name A-Z',
    'Name Z-A',
    'Marks High-Low',
    'Marks Low-High',
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Report Specific Filtering
  String _reportStackFilter = 'All';
  String _reportRemainStatusFilter = 'All';
  String _reportOnboardingStatusFilter = 'All'; // New
  String _reportEvaluationStatusFilter = 'All'; // New (Replaces boolean)
  String _reportSearchQuery = '';
  String _reportSortOption = 'Name A-Z';
  final TextEditingController _reportSearchController = TextEditingController();
  final TextEditingController _reportMinMarkController =
      TextEditingController();
  final TextEditingController _reportMinAptitudeController =
      TextEditingController();
  final TextEditingController _reportMinGDController = TextEditingController();
  final TextEditingController _reportMinHRController = TextEditingController();

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

  Future<void> _downloadCsv() async {
    try {
      final students = await _dataService.getStudents().first;
      final marksMap = await _dataService.getAllMarksStream().first;

      List<List<dynamic>> rows = [
        [
          "Name",
          "Email",
          "Stack",
          "Remain Status",
          "Aptitude",
          "Aptitude Feedback",
          "GD",
          "GD Feedback",
          "HR",
          "HR Feedback",
          "Total",
        ],
      ];

      // Filter and Sort Students for Export
      var filteredStudents = students.where((student) {
        // Search Filter (Report Specific)
        if (_reportSearchQuery.isNotEmpty) {
          if (!student.name.toLowerCase().contains(_reportSearchQuery) &&
              !student.email.toLowerCase().contains(_reportSearchQuery)) {
            return false;
          }
        }

        if (_reportStackFilter != 'All' &&
            student.stack.trim().toLowerCase() !=
                _reportStackFilter.trim().toLowerCase()) {
          return false;
        }
        if (_reportRemainStatusFilter != 'All' &&
            student.remainStatus != _reportRemainStatusFilter) {
          return false;
        }

        // Onboarding Filter
        if (_reportOnboardingStatusFilter != 'All') {
          final bool isCompleted = _reportOnboardingStatusFilter == 'Completed';
          if (student.hasCompletedOnboarding != isCompleted) return false;
        }

        final mark = marksMap[student.uid];
        bool hasMarks =
            mark != null && (mark.aptitude > 0 || mark.gd > 0 || mark.hr > 0);

        // Evaluation Filter
        if (_reportEvaluationStatusFilter != 'All') {
          bool isFullyEvaluated =
              mark != null && mark.aptitude > 0 && mark.gd > 0 && mark.hr > 0;

          if (_reportEvaluationStatusFilter == 'Fully Evaluated') {
            if (!isFullyEvaluated) return false;
          } else if (_reportEvaluationStatusFilter == 'Partially Evaluated') {
            if (!hasMarks || isFullyEvaluated) return false;
          } else if (_reportEvaluationStatusFilter == 'Pending Evaluation') {
            if (hasMarks) return false;
          } else if (_reportEvaluationStatusFilter == 'Evaluated Only') {
            if (!hasMarks) return false;
          }
        }

        // Min Mark Filter (Total)
        if (_reportMinMarkController.text.isNotEmpty) {
          final double? minMark = double.tryParse(
            _reportMinMarkController.text,
          );
          if (minMark != null) {
            final double total = _getTotalMark(mark);
            if (total < minMark) return false;
          }
        }

        // Round Specific Filters
        if (_reportMinAptitudeController.text.isNotEmpty) {
          final double? minVal = double.tryParse(
            _reportMinAptitudeController.text,
          );
          if (minVal != null) {
            if ((mark?.aptitude ?? 0) < minVal) return false;
          }
        }
        if (_reportMinGDController.text.isNotEmpty) {
          final double? minVal = double.tryParse(_reportMinGDController.text);
          if (minVal != null) {
            if ((mark?.gd ?? 0) < minVal) return false;
          }
        }
        if (_reportMinHRController.text.isNotEmpty) {
          final double? minVal = double.tryParse(_reportMinHRController.text);
          if (minVal != null) {
            if ((mark?.hr ?? 0) < minVal) return false;
          }
        }

        return true;
      }).toList();

      // Apply Sorting to Export
      filteredStudents.sort(
        (a, b) =>
            _compareStudents(a, b, marksMap, sortOption: _reportSortOption),
      );

      for (var student in filteredStudents) {
        final mark = marksMap[student.uid];
        rows.add([
          student.name,
          student.email,
          student.stack,
          student.remainStatus,
          mark?.aptitude ?? 'N/A',
          (mark?.aptitudeFeedback ?? '').replaceAll('\n', ' '),
          mark?.gd ?? 'N/A',
          (mark?.gdFeedback ?? '').replaceAll('\n', ' '),
          mark?.hr ?? 'N/A',
          (mark?.hrFeedback ?? '').replaceAll('\n', ' '),
          (mark?.aptitude ?? 0) + (mark?.gd ?? 0) + (mark?.hr ?? 0),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        // Web Download
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "candidates_marks.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else if (Platform.isWindows) {
        // Windows Save
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'candidates_marks.csv',
        );

        if (outputFile != null) {
          // FilePicker might not add extension on some platforms, verify
          if (!outputFile.toLowerCase().endsWith('.csv')) {
            outputFile = '$outputFile.csv';
          }
          final file = File(outputFile);
          await file.writeAsString(csv);
        } else {
          // User canceled
          return;
        }
      } else {
        // Mobile (Android/iOS) - Not primary target but good to have fallback
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/candidates_marks.csv');
        await file.writeAsString(csv);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Saved to ${file.path}")));
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CSV Export Successful"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error downloading CSV: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _compareStudents(
    StudentModel a,
    StudentModel b,
    Map<String, MarkModel> marksMap, {
    String? sortOption,
  }) {
    final option = sortOption ?? _selectedSortOption;
    switch (option) {
      case 'Name Z-A':
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case 'Marks High-Low':
        final markA = _getTotalMark(marksMap[a.uid]);
        final markB = _getTotalMark(marksMap[b.uid]);
        return markB.compareTo(markA);
      case 'Marks Low-High':
        final markA = _getTotalMark(marksMap[a.uid]);
        final markB = _getTotalMark(marksMap[b.uid]);
        return markA.compareTo(markB);
      case 'Name A-Z':
      default:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }

  double _getTotalMark(MarkModel? mark) {
    if (mark == null) return 0;
    return mark.aptitude + mark.gd + mark.hr;
  }

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
      _buildReportsScreen(theme), // Index 5
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
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
              Text(
                "Admin Dashboard",
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (MediaQuery.of(context).size.width > 600)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bentoJacket,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _downloadCsv,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Export CSV"),
                ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardLight,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
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
          _navItem(1, Icons.people, "Candidates", theme),
          const SizedBox(height: 12),
          _navItem(2, Icons.work, "Interviewers", theme),
          const SizedBox(height: 12),
          _navItem(3, Icons.campaign, "Broadcast", theme),
          const SizedBox(height: 12),
          _navItem(4, Icons.publish, "Publish Result", theme),
          const SizedBox(height: 12),
          _navItem(5, Icons.download_rounded, "Reports", theme),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Image.asset('assets/softlogo.png', height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: AppTheme.bentoBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/softlogo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              _navItem(0, Icons.dashboard, "Overview", theme),
              const SizedBox(height: 12),
              _navItem(1, Icons.people, "Candidates", theme),
              const SizedBox(height: 12),
              _navItem(2, Icons.work, "Interviewers", theme),
              const SizedBox(height: 12),
              _navItem(3, Icons.campaign, "Broadcast", theme),
              const SizedBox(height: 12),
              _navItem(4, Icons.publish, "Publish Result", theme),
              const SizedBox(height: 12),
              _navItem(5, Icons.download_rounded, "Reports", theme),
              const Spacer(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String title, ThemeData theme) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        // On mobile, close drawer after selection
        if (MediaQuery.of(context).size.width <= 800) {
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
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        // Filters
        // Filters
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  _buildFilterChip(
                    "Stack",
                    _selectedStackFilter,
                    ['All', ..._stackOptions],
                    (val) => setState(() => _selectedStackFilter = val),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    "Status",
                    _selectedRemainStatusFilter,
                    ['All', ..._remainStatusOptions],
                    (val) => setState(() => _selectedRemainStatusFilter = val),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    "Marks",
                    _selectedMarkFilter,
                    ['All', 'Marked', 'Unmarked'],
                    (val) => setState(() => _selectedMarkFilter = val),
                  ),
                  const SizedBox(width: 12),
                  // Sorting Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 16),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedSortOption,
                          underline: const SizedBox(),
                          isDense: true,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          items: _sortOptions.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedSortOption = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Grid of Bento Stats
        StreamBuilder<Map<String, MarkModel>>(
          stream: _dataService.getAllMarksStream(),
          builder: (context, markSnapshot) {
            final marksMap = markSnapshot.data ?? {};

            return StreamBuilder<List<StudentModel>>(
              stream: _dataService.getStudents(),
              builder: (context, snapshot) {
                final allStudents = snapshot.data ?? [];
                final filtered = allStudents.where((s) {
                  if (_selectedStackFilter != 'All' &&
                      s.stack.trim().toLowerCase() !=
                          _selectedStackFilter.trim().toLowerCase()) {
                    return false;
                  }
                  if (_selectedRemainStatusFilter != 'All' &&
                      s.remainStatus != _selectedRemainStatusFilter) {
                    return false;
                  }
                  return true;
                }).toList();
                int total = filtered.length;

                // Calculate marked count based on filtered students
                int markedCount = filtered.where((s) {
                  final m = marksMap[s.uid];
                  return m != null && (m.aptitude > 0 || m.gd > 0 || m.hr > 0);
                }).length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // If constrained width is less than 500, stack them.
                    bool isNarrow = constraints.maxWidth < 600;

                    List<Widget> cards = [
                      if (isNarrow) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _bentoStatCard(
                                "Candidates",
                                "$total",
                                AppTheme.bentoJacket,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _bentoStatCard(
                                "Marked",
                                "$markedCount",
                                AppTheme.bentoAccent,
                                Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _bentoStatCard(
                            "Sessions",
                            "Active",
                            AppTheme.bentoSurface,
                            Colors.black87,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _bentoStatCard(
                            "Candidates",
                            "$total",
                            AppTheme.bentoJacket,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _bentoStatCard(
                            "Marked",
                            "$markedCount",
                            AppTheme.bentoAccent,
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
                    ];

                    if (isNarrow) {
                      return Column(children: cards);
                    } else {
                      return Row(children: cards);
                    }
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 15),

        Container(
          width: double.infinity,
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
              StreamBuilder<Map<String, MarkModel>>(
                stream: _dataService.getAllMarksStream(),
                builder: (context, markSnap) {
                  final marksMap = markSnap.data ?? {};

                  return StreamBuilder<List<StudentModel>>(
                    stream: _dataService.getStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allStudents = snapshot.data ?? [];

                      // Filter: Only show students who have marks AND match selected filters
                      final markedStudents = allStudents.where((s) {
                        final m = marksMap[s.uid];
                        bool hasMarks =
                            m != null &&
                            (m.aptitude > 0 || m.gd > 0 || m.hr > 0);

                        // 1. Must always have marks for this specific list (as it's "Assessment Progress")
                        if (!hasMarks) return false;

                        // 2. Search Query (Name or Email)
                        if (_searchQuery.isNotEmpty) {
                          if (!s.name.toLowerCase().contains(_searchQuery) &&
                              !s.email.toLowerCase().contains(_searchQuery)) {
                            return false;
                          }
                        }

                        // 3. Must match Stack Filter
                        if (_selectedStackFilter != 'All' &&
                            s.stack.trim().toLowerCase() !=
                                _selectedStackFilter.trim().toLowerCase()) {
                          return false;
                        }

                        // 4. Must match Status Filter
                        if (_selectedRemainStatusFilter != 'All' &&
                            s.remainStatus != _selectedRemainStatusFilter) {
                          return false;
                        }

                        // 5. Mark Filter (Already checked hasMarks, but respecting the UI Toggle)
                        if (_selectedMarkFilter == 'Unmarked')
                          return false; // This list only shows marked

                        return true;
                      }).toList();

                      // Apply Sorting
                      markedStudents.sort(
                        (a, b) => _compareStudents(a, b, marksMap),
                      );

                      if (markedStudents.isEmpty) {
                        return Text("No marked students yet.");
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: markedStudents.length,
                        itemBuilder: (context, index) {
                          final student = markedStudents[index];
                          final marks = marksMap[student.uid];

                          return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentProfilePage(
                                          student: student,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: AppTheme.bentoDecoration(
                                      color: AppTheme.softWhite,
                                      radius: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppTheme.bentoBg,
                                              child: Text(
                                                student.name.isNotEmpty
                                                    ? student.name[0]
                                                    : '?',
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Wrap(
                                          children: [
                                            _miniBadge(
                                              "APT",
                                              marks?.aptitude ?? 0,
                                              max: 25,
                                            ),
                                            const SizedBox(width: 4),
                                            _miniBadge(
                                              "GD",
                                              marks?.gd ?? 0,
                                              max: 25,
                                            ),
                                            const SizedBox(width: 4),
                                            _miniBadge(
                                              "HR",
                                              marks?.hr ?? 0,
                                              max: 25,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fade(delay: (index * 100).ms)
                              .slideX(begin: 0.1, end: 0);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _bentoStatCard(String label, String value, Color bg, Color text) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppTheme.bentoDecoration(color: bg, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
          Text(label, style: TextStyle(color: text.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, double score, {double max = 100}) {
    final color = score > 0 ? _getMarkColor(score, max: max) : Colors.grey[300];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.1),
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

  Color _getMarkColor(double score, {double max = 100}) {
    final percentage = score / max;
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.5) return Colors.orange;
    if (percentage >= 0.4) return Colors.amber;
    return Colors.redAccent;
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
                width: double.infinity,
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 16 : 24,
                ),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoAccent,
                  radius: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == 'interviewee' ? "Candidates" : "Interviewers",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 20
                            : 24,
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
                child:
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.bentoDecoration(
                            color: AppTheme.bentoSurface,
                            radius: 32,
                          ),
                          child: const Icon(Icons.add, size: 32),
                        )
                        .animate()
                        .fade(delay: 200.ms)
                        .scale(curve: Curves.easeOutBack),
              ),
            ],
          ],
        ),
        const SizedBox(height: 15),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 15),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  if (role == 'interviewee') ...[
                    _buildFilterChip(
                      "Stack",
                      _selectedStackFilter,
                      ['All', ..._stackOptions],
                      (val) => setState(() => _selectedStackFilter = val),
                    ),
                    const SizedBox(width: 5),
                    _buildFilterChip(
                      "Status",
                      _selectedRemainStatusFilter,
                      ['All', ..._remainStatusOptions],
                      (val) =>
                          setState(() => _selectedRemainStatusFilter = val),
                    ),
                    const SizedBox(width: 5),
                    _buildFilterChip(
                      "Marks",
                      _selectedMarkFilter,
                      ['All', 'Marked', 'Unmarked'],
                      (val) => setState(() => _selectedMarkFilter = val),
                    ),
                    const SizedBox(width: 5),
                    // Sorting Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort, size: 16),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedSortOption,
                            underline: const SizedBox(),
                            isDense: true,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            items: _sortOptions.map((e) {
                              return DropdownMenuItem(value: e, child: Text(e));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedSortOption = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.bentoDecoration(
            color: AppTheme.bentoSurface,
            radius: 32,
          ),
          child: StreamBuilder<Map<String, MarkModel>>(
            stream: _dataService.getAllMarksStream(), // Need marks for filter
            builder: (context, markSnap) {
              final marksMap = markSnap.data ?? {};

              return StreamBuilder<List<UserModel>>(
                stream: _dataService.getUsersByRole(role),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allUsers = snapshot.data ?? [];

                  // Apply Filters
                  final users = allUsers.where((user) {
                    // Search Filter
                    if (_searchQuery.isNotEmpty) {
                      if (!user.name.toLowerCase().contains(_searchQuery) &&
                          !user.email.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                    }

                    if (user is! StudentModel) return true;
                    if (_selectedStackFilter != 'All' &&
                        user.stack.trim().toLowerCase() !=
                            _selectedStackFilter.trim().toLowerCase()) {
                      // Case insensitive check
                      return false;
                    }
                    if (_selectedRemainStatusFilter != 'All' &&
                        user.remainStatus != _selectedRemainStatusFilter) {
                      return false;
                    }
                    // Mark Filter
                    if (_selectedMarkFilter != 'All') {
                      final m = marksMap[user.uid];
                      bool hasMarks =
                          m != null && (m.aptitude > 0 || m.gd > 0 || m.hr > 0);
                      if (_selectedMarkFilter == 'Marked' && !hasMarks)
                        return false;
                      if (_selectedMarkFilter == 'Unmarked' && hasMarks)
                        return false;
                    }

                    return true;
                  }).toList();

                  // Apply Sorting
                  users.sort((a, b) {
                    if (a is StudentModel && b is StudentModel) {
                      return _compareStudents(a, b, marksMap);
                    }
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      // ... rest of the item builder
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            InkWell(
                                  onTap: user is StudentModel
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StudentProfilePage(
                                                    student: user,
                                                  ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name.isNotEmpty
                                                    ? user.name
                                                    : (user is StudentModel
                                                          ? "Candidate"
                                                          : user.role.name[0]
                                                                    .toUpperCase() +
                                                                user.role.name
                                                                    .substring(
                                                                      1,
                                                                    )),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                user.email,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                          onPressed: () =>
                                              _showEditUserDialog(user),
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
                                )
                                .animate()
                                .fade(delay: (index * 50).ms)
                                .slideY(begin: 0.1, end: 0),
                      );
                    },
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
    // Default Status
    String selectedStatus = _remainStatusOptions.first;

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
              // Replaced TextField with Dropdown
              DropdownButtonFormField<String>(
                value: _stackOptions.contains(stackController.text)
                    ? stackController.text
                    : null,
                decoration: InputDecoration(
                  labelText: "Stack / Discipline",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _stackOptions.map((stack) {
                  return DropdownMenuItem(value: stack, child: Text(stack));
                }).toList(),
                onChanged: (val) {
                  if (val != null) stackController.text = val;
                },
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
              const SizedBox(height: 16),
              // Status Dropdown
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: "Status",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _remainStatusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedStatus = val;
                },
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
                  selectedStatus,
                );
                if (context.mounted) Navigator.pop(context);
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
                if (context.mounted) Navigator.pop(context);
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
    // Status Variable for Edit
    String selectedStatus = user is StudentModel
        ? user.remainStatus
        : 'Main Project';

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
                controller: TextEditingController(text: user.email),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email (Read-Only)",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                // Replaced TextField with Dropdown for Edit
                DropdownButtonFormField<String>(
                  value: _stackOptions.contains(stackController.text)
                      ? stackController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: "Stack / Discipline",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _stackOptions.map((stack) {
                    return DropdownMenuItem(value: stack, child: Text(stack));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) stackController.text = val;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _remainStatusOptions.contains(selectedStatus)
                      ? selectedStatus
                      : null,
                  decoration: InputDecoration(
                    labelText: "Status",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _remainStatusOptions.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedStatus = val;
                  },
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
                  remainStatus: selectedStatus,
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
              if (context.mounted) Navigator.pop(context);
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
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage(userType: "Admin")),
        (route) => false,
      );
    }
  }

  Widget _buildBroadcastScreen(ThemeData theme) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final minMarksController = TextEditingController(); // New
    String targetRole = 'all';
    final isMobile = MediaQuery.of(context).size.width < 600;

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
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: AppTheme.bentoDecoration(
              color: AppTheme.bentoJacket,
              radius: 32,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: isMobile ? 24 : 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Global Broadcast",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Send instant alerts to users",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Quick Presets",
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isMobile ? 90 : 100,
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
                      width: isMobile ? 140 : 160,
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
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
            padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: targetRole,
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
                        ),
                        const SizedBox(height: 16),
                        // Min Marks Filter
                        if (targetRole == 'interviewee' || targetRole == 'all')
                          TextField(
                            controller: minMarksController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Min Marks Filter (Optional)",
                              hintText: "e.g. 10, 20, 30...",
                              filled: true,
                              fillColor: AppTheme.bentoBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                      ],
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
                          messageController.text.isEmpty) {
                        return;
                      }
                      await _dataService.broadcastNotification(
                        NotificationModel(
                          id: '',
                          title: titleController.text,
                          message: messageController.text,
                          timestamp: DateTime.now(),
                          targetRole: targetRole,
                          minMarks: double.tryParse(minMarksController.text),
                        ),
                      );
                      titleController.clear();
                      messageController.clear();
                      minMarksController.clear();
                      if (!mounted) return;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final double containerPadding = isMobile ? 16 : 32;
        final double titleSize = isMobile ? 20 : 24;
        final double statusSize = isMobile ? 14 : 18;
        final double iconSize = isMobile ? 48 : 64;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(containerPadding),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoAccent,
                  radius: 40,
                ),
                child: Column(
                  children: [
                    Icon(Icons.publish, color: Colors.white, size: iconSize),
                    const SizedBox(height: 16),
                    Text(
                      "Results Visibility",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Control when students can view their final assessment marks.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    StreamBuilder<bool>(
                      stream: _dataService.getResultsPublishedStream(),
                      builder: (context, snapshot) {
                        final isPublished = snapshot.data ?? false;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isPublished
                                      ? "STATUS: LIVE"
                                      : "STATUS: RESTRICTED",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: statusSize,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Switch(
                                value: isPublished,
                                activeThumbColor: Colors.greenAccent,
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
                padding: EdgeInsets.all(containerPadding),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoSurface,
                  radius: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Guidelines",
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const BulletItem(
                      "Ensure all interviewers have submitted marks.",
                    ),
                    const BulletItem(
                      "Unpublishing will hide results immediately.",
                    ),
                    const BulletItem(
                      "Students will receive a notification if enabled.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by Name or Email...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          DropdownButton<String>(
            value: selectedValue,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            items: options.map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (val) {
              if (val != null) onSelected(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsScreen(ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: AppTheme.bentoDecoration(
            color: AppTheme.bentoJacket,
            radius: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reports & Downloads",
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Generate and download CSV reports based on student performance.",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Search Bar for Reports
              TextField(
                controller: _reportSearchController,
                decoration: InputDecoration(
                  hintText: "Search by Name or Email...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _reportSearchQuery = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  _buildFilterChip(
                    "Stack",
                    _reportStackFilter,
                    ['All', ..._stackOptions],
                    (val) => setState(() => _reportStackFilter = val),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    "Status",
                    _reportRemainStatusFilter,
                    ['All', ..._remainStatusOptions],
                    (val) => setState(() => _reportRemainStatusFilter = val),
                  ),
                  const SizedBox(width: 12),
                  // Report Sorting
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 16),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _reportSortOption,
                          underline: const SizedBox(),
                          isDense: true,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          items: _sortOptions.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _reportSortOption = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterChip(
                    "Onboarding",
                    _reportOnboardingStatusFilter,
                    ['All', 'Completed', 'Pending'],
                    (val) =>
                        setState(() => _reportOnboardingStatusFilter = val),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    "Evaluation",
                    _reportEvaluationStatusFilter,
                    [
                      'All',
                      'Evaluated Only',
                      'Fully Evaluated',
                      'Partially Evaluated',
                      'Pending Evaluation',
                    ],
                    (val) =>
                        setState(() => _reportEvaluationStatusFilter = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mark Filters
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _reportMinMarkController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min Total",
                        prefixIcon: const Icon(Icons.functions),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _reportMinAptitudeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min Aptitude",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _reportMinGDController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min GD",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _reportMinHRController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min HR",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bentoJacket,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _downloadCsv,
                  icon: const Icon(Icons.download),
                  label: const Text("GENERATE & DOWNLOAD CSV"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double fontSize = isMobile ? 14 : 16;
    final double bulletSize = isMobile ? 16 : 18;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: bulletSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.bentoJacket,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.black87, fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
