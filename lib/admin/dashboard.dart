import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/services/resume_service.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/models/user_models.dart';
import 'dart:convert';
import 'package:mockathon/core/web_helper.dart';

import 'package:mockathon/admin/student_profile_page.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockathon/core/app_config.dart';
import 'package:mockathon/admin/screens/settings_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  static int _selectedIndex = 0;
  UserModel? _currentUserProfile;

  final List<String> _labels = [
    "Dashboard",
    "Candidates",
    "Interviewers",
    "Admins",
    "Broadcast",
    "Publish",
    "Reports",
    "Mockathons",
    "Settings",
  ];

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.badge_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.campaign_rounded,
    Icons.publish_rounded,
    Icons.assessment_rounded,
    Icons.date_range_rounded,
    Icons.settings_rounded,
  ];

  // Filtering
  String _selectedStackFilter = 'All';
  String _selectedRemainStatusFilter = 'All';
  String _selectedMarkFilter = 'All'; // New Mark Filter
  String _searchQuery = ''; // New Search Query
  String _selectedBranchFilter = 'All'; // New Branch Filter
  String _selectedMockathonFilter = 'All'; // New Mockathon Session Filter
  String _selectedSortOption = 'Name A-Z';
  final List<String> _sortOptions = [
    'Name A-Z',
    'Name Z-A',
    'Marks High-Low',
    'Marks Low-High',
  ];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mockathonNameController = TextEditingController();
  DateTime? _selectedMockathonDate;
  StreamSubscription<String?>? _activeMockathonSubscription;

  void _listenToActiveMockathon(String branch) {
    _activeMockathonSubscription?.cancel();
    _activeMockathonSubscription = _dataService
        .getActiveMockathonIdStream(branch: branch)
        .listen((activeId) {
      if (mounted) {
        setState(() {
          _selectedMockathonFilter = activeId ?? 'All';
        });
      }
    });
  }

  void _updateBranchFilter(String val) {
    setState(() {
      _selectedBranchFilter = val;
    });
    _listenToActiveMockathon(val);
  }

  Widget _buildMockathonFilterDropdown({String? branch}) {
    final activeBranch = branch ?? _selectedBranchFilter;
    return StreamBuilder<List<MockathonModel>>(
      stream: _dataService.getMockathons(branch: activeBranch),
      builder: (context, snapshot) {
        final mockathons = snapshot.data ?? [];
        final items = <DropdownMenuItem<String>>[
          const DropdownMenuItem(value: 'All', child: Text("All Sessions")),
        ];
        for (var m in mockathons) {
          items.add(DropdownMenuItem(value: m.id, child: Text(m.name)));
        }

        final currentVal = items.any((i) => i.value == _selectedMockathonFilter)
            ? _selectedMockathonFilter
            : 'All';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, size: 16, color: AppTheme.bentoJacket),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: currentVal,
                underline: const SizedBox(),
                isDense: true,
                items: items,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMockathonFilter = val);
                  }
                },
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted && profile != null) {
        setState(() {
          _currentUserProfile = profile;
          if (profile.branch != 'All') {
            _selectedBranchFilter = profile.branch;
          }
        });
        _listenToActiveMockathon(_selectedBranchFilter);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mockathonNameController.dispose();
    _activeMockathonSubscription?.cancel();
    super.dispose();
  }

  // Report Specific Filtering
  String _reportStackFilter = 'All';
  String _reportRemainStatusFilter = 'All';
  String _reportOnboardingStatusFilter = 'All'; // New
  String _reportEvaluationStatusFilter = 'All'; // New (Replaces boolean)
  String _reportBranchFilter = 'All'; // New CSV Export Branch Isolator
  String _reportSearchQuery = '';
  String _reportSortOption = 'Name A-Z';
  final TextEditingController _reportSearchController = TextEditingController();
  final TextEditingController _reportMinMarkController =
      TextEditingController();
  final TextEditingController _reportMinAptitudeController =
      TextEditingController();
  final TextEditingController _reportMinGDController = TextEditingController();
  final TextEditingController _reportMinHRController = TextEditingController();
  final TextEditingController _reportMinTechnicalController =
      TextEditingController();
  final TextEditingController _reportMinMachineTestController =
      TextEditingController();

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

  Future<void> _downloadCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final students = await _dataService.getStudents(
        branch: _reportBranchFilter != 'All' ? _reportBranchFilter : null,
        mockathonId: _selectedMockathonFilter != 'All' ? _selectedMockathonFilter : null,
      ).first;
      final marksMap = await _dataService.getAllMarksStream(
        mockathonId: _selectedMockathonFilter != 'All' ? _selectedMockathonFilter : null,
      ).first;

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
          "Technical",
          "Technical Feedback",
          "Machine Test",
          "Machine Test Feedback",
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

        // Branch Isolation Filter for Super Admins
        if (_reportBranchFilter != 'All' &&
            student.branch.trim() != _reportBranchFilter.trim()) {
          return false;
        }

        final mark = marksMap[student.uid];
        bool hasMarks =
            mark != null && (mark.aptitude > 0 || mark.gd > 0 || mark.hr > 0);

        // Evaluation Filter
        if (_reportEvaluationStatusFilter != 'All') {
          bool isFullyEvaluated =
              mark != null &&
              mark.aptitude > 0 &&
              mark.gd > 0 &&
              mark.hr > 0 &&
              mark.technical > 0 &&
              mark.machineTest > 0;

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
        if (_reportMinTechnicalController.text.isNotEmpty) {
          final double? minVal = double.tryParse(
            _reportMinTechnicalController.text,
          );
          if (minVal != null) {
            if ((mark?.technical ?? 0) < minVal) return false;
          }
        }
        if (_reportMinMachineTestController.text.isNotEmpty) {
          final double? minVal = double.tryParse(
            _reportMinMachineTestController.text,
          );
          if (minVal != null) {
            if ((mark?.machineTest ?? 0) < minVal) return false;
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
          mark?.technical ?? 'N/A',
          (mark?.technicalFeedback ?? '').replaceAll('\n', ' '),
          mark?.machineTest ?? 'N/A',
          (mark?.machineTestFeedback ?? '').replaceAll('\n', ' '),
          (mark?.aptitude ?? 0) +
              (mark?.gd ?? 0) +
              (mark?.hr ?? 0) +
              (mark?.technical ?? 0) +
              (mark?.machineTest ?? 0),
        ]);
      }

      String csv = ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        // Web Download using WebHelper for cross-platform/WASM compatibility
        WebHelper.downloadFile(
          bytes: utf8.encode(csv),
          fileName: "candidates_marks.csv",
          type: 'text/csv',
        );
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
        messenger.showSnackBar(SnackBar(content: Text("Saved to ${file.path}")));
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text("CSV Export Successful"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Export Error: $e");
      messenger.showSnackBar(
        SnackBar(
          content: Text("Error downloading CSV: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
    return mark.aptitude +
        mark.gd +
        mark.hr +
        mark.technical +
        mark.machineTest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dashboard Content
    final List<Widget> pages = [
      _buildAssessmentOverview(theme),
      _buildUserManagement('interviewee', theme),
      _buildUserManagement('interviewer', theme),
      _buildUserManagement('admin', theme),
      _buildBroadcastScreen(theme),
      _buildPublishScreen(theme),
      _buildReportsScreen(theme),
      _buildMockathonsScreen(theme),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bentoBg, // Using the suggested white/sand theme
      key: _scaffoldKey,
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
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
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
      width: 260,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(
        color: Colors.white,
        radius: 20,
        shadow: true,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            AppConfigScope.of(context)?.appName.toUpperCase() ?? "MOCKATHON",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppTheme.bentoJacket,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < _labels.length; i++) ...[
                    _navItem(i, _icons[i], _labels[i], theme),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < _labels.length; i++) ...[
                        _navItem(i, _icons[i], _labels[i], theme),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
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
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bentoAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, 
              color: isSelected ? AppTheme.bentoAccent : const Color(0xFF757575),
              size: 22
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppTheme.bentoAccent : const Color(0xFF424242),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
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
                  _buildFilterChip(
                    "Branch",
                    _selectedBranchFilter,
                    ['All', ..._branchOptions],
                    (val) => _updateBranchFilter(val),
                  ),
                  const SizedBox(width: 12),
                  _buildMockathonFilterDropdown(),
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
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                            if (val != null) {
                              setState(() => _selectedSortOption = val);
                            }
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
          stream: _dataService.getAllMarksStream(
            mockathonId: _selectedMockathonFilter != 'All'
                ? _selectedMockathonFilter
                : null,
          ),
          builder: (context, markSnapshot) {
            final marksMap = markSnapshot.data ?? {};

            return StreamBuilder<List<StudentModel>>(
              stream: _dataService.getStudents(
                branch: _selectedBranchFilter,
                mockathonId: _selectedMockathonFilter != 'All'
                    ? _selectedMockathonFilter
                    : null,
              ),
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
                  return m != null &&
                      (m.aptitude > 0 ||
                          m.gd > 0 ||
                          m.hr > 0 ||
                          m.technical > 0 ||
                          m.machineTest > 0);
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
                        _bentoStatCard(
                          "Sessions",
                          "Active",
                          AppTheme.bentoSurface,
                          Colors.black87,
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: cards,
                      );
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
                stream: _dataService.getAllMarksStream(
                  mockathonId: _selectedMockathonFilter != 'All'
                      ? _selectedMockathonFilter
                      : null,
                ),
                builder: (context, markSnap) {
                  final marksMap = markSnap.data ?? {};

                  return StreamBuilder<List<StudentModel>>(
                    stream: _dataService.getStudents(
                      branch: _selectedBranchFilter,
                      mockathonId: _selectedMockathonFilter != 'All'
                          ? _selectedMockathonFilter
                          : null,
                    ),
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
                            (m.aptitude > 0 ||
                                m.gd > 0 ||
                                m.hr > 0 ||
                                m.technical > 0 ||
                                m.machineTest > 0);

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
                        if (_selectedMarkFilter == 'Unmarked') return false;

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
                                            const SizedBox(width: 4),
                                            _miniBadge(
                                              "TECH",
                                              marks?.technical ?? 0,
                                              max: 25,
                                            ),
                                            const SizedBox(width: 4),
                                            _miniBadge(
                                              "MACH",
                                              marks?.machineTest ?? 0,
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
      height: isMobile ? 80 : 96,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: AppTheme.bentoDecoration(color: bg, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: text,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: text.withValues(alpha: 0.7),
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, double score, {double max = 100}) {
    final color = score > 0 ? _getMarkColor(score, max: max) : Colors.grey[300];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  MediaQuery.of(context).size.width < 600 ? 12 : 16,
                ),
                decoration: AppTheme.bentoDecoration(
                  color: Colors.white,
                  radius: 24,
                  shadow: true,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == 'interviewee'
                          ? "Candidates"
                          : role == 'interviewer'
                          ? "Interviewers"
                          : role == 'admin'
                          ? "Admins"
                          : role[0].toUpperCase() + role.substring(1),
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 20
                            : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      "Management",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (role == 'admin' ||
                role == 'interviewer' ||
                role == 'interviewee') ...[
              const SizedBox(width: 16),
              InkWell(
                onTap: () => role == 'interviewee'
                    ? _showAddStudentDialog()
                    : _showAddStaffDialog(role),
                child:
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.bentoDecoration(
                            color: AppTheme.bentoAccent,
                            radius: 20,
                            shadow: true,
                          ),
                          child: const Icon(Icons.add, size: 28, color: Colors.white),
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
                  _buildFilterChip(
                    "Branch",
                    _selectedBranchFilter,
                    ['All', ..._branchOptions],
                    (val) => _updateBranchFilter(val),
                  ),
                  const SizedBox(width: 5),
                  if (role == 'interviewee') ...[
                    _buildMockathonFilterDropdown(),
                    const SizedBox(width: 5),
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
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                              if (val != null) {
                                setState(() => _selectedSortOption = val);
                              }
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
            stream: _dataService.getAllMarksStream(
              mockathonId: _selectedMockathonFilter != 'All'
                  ? _selectedMockathonFilter
                  : null,
            ), // Need marks for filter
            builder: (context, markSnap) {
              final marksMap = markSnap.data ?? {};

              return StreamBuilder<List<UserModel>>(
                stream: _dataService.getUsersByRole(
                  role,
                  branch: _selectedBranchFilter,
                  mockathonId: role == 'interviewee' && _selectedMockathonFilter != 'All'
                      ? _selectedMockathonFilter
                      : null,
                ),
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
                          m != null &&
                          (m.aptitude > 0 ||
                              m.gd > 0 ||
                              m.hr > 0 ||
                              m.technical > 0 ||
                              m.machineTest > 0);
                      if (_selectedMarkFilter == 'Marked' && !hasMarks) {
                        return false;
                      }
                      if (_selectedMarkFilter == 'Unmarked' && hasMarks) {
                        return false;
                      }
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

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              role == 'interviewee'
                                  ? Icons.person_off_outlined
                                  : Icons.badge_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No ${role == 'interviewee'
                                  ? 'Candidates'
                                  : role == 'interviewer'
                                  ? 'Interviewers'
                                  : 'Admins'} found ${_selectedBranchFilter != 'All' ? 'in $_selectedBranchFilter' : ''}",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedBranchFilter = 'All';
                                  _selectedStackFilter = 'All';
                                  _selectedRemainStatusFilter = 'All';
                                  _selectedMarkFilter = 'All';
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text("Clear All Filters"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Showing ${users.length} of ${allUsers.length} ${role == 'interviewee'
                                  ? 'Candidates'
                                  : role == 'interviewer'
                                  ? 'Interviewers'
                                  : 'Admins'}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (users.length < allUsers.length)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedBranchFilter = 'All';
                                    _selectedStackFilter = 'All';
                                    _selectedRemainStatusFilter = 'All';
                                    _selectedMarkFilter = 'All';
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text(
                                  "Reset",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                                          builder: (_) =>
                                              StudentProfilePage(student: user),
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
                                                                .substring(1)),
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
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bentoAccent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.branch,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.bentoAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (user is StudentModel)
                                      IconButton(
                                        icon: Icon(
                                          Icons.download_rounded,
                                          color: user.cvUrl != null
                                              ? Colors.green[300]
                                              : Colors.grey[300],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          if (user.cvUrl != null) {
                                            ResumeService().downloadResume(
                                              user.cvUrl!,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "No resume uploaded by this candidate",
                                                ),
                                              ),
                                            );
                                          }
                                        },
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
                            ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
                          );
                        },
                      ),
                    ],
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
    String selectedBranch =
        _currentUserProfile?.branch != 'All' && _currentUserProfile != null
        ? _currentUserProfile!.branch
        : (_selectedBranchFilter != 'All'
              ? _selectedBranchFilter
              : 'Kozhikode');

    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                DropdownButtonFormField<String>(
                  initialValue: stackController.text.isNotEmpty
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
                    if (val != null) {
                      setDialogState(() => stackController.text = val);
                    }
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
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
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
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedBranch,
                  decoration: InputDecoration(
                    labelText: "Branch",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _branchOptions
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedBranch = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bentoJacket,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final activeMockathonId = await _dataService
                            .getActiveMockathonIdStream(branch: selectedBranch)
                            .first;
                        await _authService.registerStudent(
                          emailController.text,
                          passController.text,
                          nameController.text,
                          stackController.text,
                          selectedStatus,
                          selectedBranch,
                          mockathonId: activeMockathonId,
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Student added successfully!"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error adding student: $e")),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("ADD", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStaffDialog(String role) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    String selectedBranch =
        _currentUserProfile?.branch != 'All' && _currentUserProfile != null
        ? _currentUserProfile!.branch
        : (_selectedBranchFilter != 'All' ? _selectedBranchFilter : 'All');

    String selectedRole = role == 'admin' ? 'admin' : 'interviewer';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Add New ${selectedRole[0].toUpperCase() + selectedRole.substring(1)}",
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
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: "Role",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'interviewer',
                    child: Text("Interviewer"),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text("Admin")),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedBranch,
                decoration: InputDecoration(
                  labelText: "Branch",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['All', ..._branchOptions]
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedBranch = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bentoJacket,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await _authService.registerStaff(
                          emailController.text,
                          passController.text,
                          nameController.text,
                          selectedRole == 'interviewer'
                              ? UserRole.interviewer
                              : UserRole.admin,
                          selectedBranch,
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${selectedRole[0].toUpperCase() + selectedRole.substring(1)} added successfully!",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error adding $selectedRole: $e"),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("ADD", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
    String selectedBranch =
        (user is StudentModel ? _branchOptions : ['All', ..._branchOptions])
            .contains(user.branch)
        ? user.branch
        : 'Kozhikode';

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
                  initialValue: _stackOptions.contains(stackController.text)
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
                  initialValue: _remainStatusOptions.contains(selectedStatus)
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedBranch,
                decoration: InputDecoration(
                  labelText: "Branch",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    (user is StudentModel
                            ? _branchOptions
                            : ['All', ..._branchOptions])
                        .map((branch) {
                          return DropdownMenuItem(
                            value: branch,
                            child: Text(branch),
                          );
                        })
                        .toList(),
                onChanged: (val) {
                  if (val != null) selectedBranch = val;
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
              UserModel updatedUser;
              if (user is StudentModel) {
                updatedUser = StudentModel(
                  uid: user.uid,
                  email: user.email,
                  name: nameController.text,
                  stack: stackController.text,
                  remainStatus: selectedStatus,
                  branch: selectedBranch,
                  randomId: user.randomId,
                  notifications: user.notifications,
                  cvUrl: user.cvUrl,
                  hasCompletedOnboarding: user.hasCompletedOnboarding,
                );
              } else {
                updatedUser = UserModel(
                  uid: user.uid,
                  email: user.email,
                  name: nameController.text,
                  branch: selectedBranch,
                  role: user.role,
                  hasCompletedOnboarding: user.hasCompletedOnboarding,
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
    String targetBranch = _currentUserProfile?.branch ?? 'All';
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
                        color: (p['color'] as Color).withValues(alpha: 0.1),
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

                        DropdownButtonFormField<String>(
                          initialValue: targetBranch,
                          decoration: InputDecoration(
                            labelText: "Target Branch",
                            filled: true,
                            fillColor: AppTheme.bentoBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['All', ..._branchOptions].map((b) {
                            return DropdownMenuItem(value: b, child: Text(b));
                          }).toList(),
                          onChanged: (val) =>
                              setInnerState(() => targetBranch = val!),
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
                          branch: targetBranch,
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
        final actualBranch = _selectedBranchFilter;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
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
                    const SizedBox(height: 24),
                    _buildFilterChip(
                      "Branch",
                      _selectedBranchFilter,
                      ['All', ..._branchOptions],
                      (val) => _updateBranchFilter(val),
                    ),
                    const SizedBox(height: 32),
                    StreamBuilder<bool>(
                      key: ValueKey(actualBranch),
                      stream: _dataService.getResultsPublishedStream(
                        branch: actualBranch,
                      ),
                      builder: (context, snapshot) {
                        final isPublished = snapshot.data ?? false;
                        final bool isAllSelected = actualBranch == 'All';

                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      isPublished
                                          ? "${actualBranch.toUpperCase()}: LIVE"
                                          : "${actualBranch.toUpperCase()}: RESTRICTED",
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
                                    onChanged: isAllSelected
                                        ? null
                                        : (val) => _confirmPublishResults(
                                            val,
                                            actualBranch,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAllSelected)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  "⚠️ Please select a specific branch to update results visibility",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
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
                      "Publishing results allows students in that specific branch to see their marks.",
                    ),
                    const BulletItem(
                      "Ensure all assessments for a branch are completed before publishing.",
                    ),
                    const BulletItem(
                      "You can toggle visibility off at any time to restrict access.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _confirmPublishResults(bool value, String branch) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          value ? "Publish Results for $branch?" : "Hide Results for $branch?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          value
              ? "This will make marks visible to all $branch students immediately."
              : "This will hide marks from all $branch students.",
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
      await _dataService.updateResultsPublished(value, branch: branch);
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
    ValueChanged<String>? onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
              if (val != null) onSelected?.call(val);
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                  _buildFilterChip(
                    "Branch",
                    _reportBranchFilter,
                    ['All', ..._branchOptions],
                    (val) {
                      setState(() => _reportBranchFilter = val);
                      _listenToActiveMockathon(val);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildMockathonFilterDropdown(branch: _reportBranchFilter),
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
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                            if (val != null) {
                              setState(() => _reportSortOption = val);
                            }
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
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _reportMinTechnicalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min Technical",
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
                      controller: _reportMinMachineTestController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Min Machine Test",
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

  Widget _buildMockathonsScreen(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final double containerPadding = isMobile ? 16 : 24;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(containerPadding),
                decoration: AppTheme.bentoDecoration(
                  color: Colors.white,
                  radius: 24,
                  shadow: true,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mockathon Sessions",
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage mock interview sessions by date, control active sessions, and migrate legacy data.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isMobile) ...[
                _buildCreateMockathonCard(theme),
                const SizedBox(height: 24),
                _buildMigrationCard(theme),
                const SizedBox(height: 24),
                _buildMockathonsListCard(theme),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildCreateMockathonCard(theme),
                          const SizedBox(height: 24),
                          _buildMigrationCard(theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildMockathonsListCard(theme),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateMockathonCard(ThemeData theme) {
    String createBranch = _currentUserProfile?.branch != 'All' && _currentUserProfile != null
        ? _currentUserProfile!.branch
        : (_selectedBranchFilter != 'All' ? _selectedBranchFilter : 'Kozhikode');

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.bentoDecoration(
            color: Colors.white,
            radius: 24,
            shadow: true,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create New Session",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mockathonNameController,
                decoration: InputDecoration(
                  labelText: "Session Name (e.g. Mockathon July)",
                  filled: true,
                  fillColor: AppTheme.bentoBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedMockathonDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setCardState(() {
                      _selectedMockathonDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.bentoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMockathonDate == null
                            ? "Select Session Date"
                            : "Date: ${_selectedMockathonDate!.year}-${_selectedMockathonDate!.month.toString().padLeft(2, '0')}-${_selectedMockathonDate!.day.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: _selectedMockathonDate == null ? Colors.grey[700] : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.calendar_month, color: AppTheme.bentoJacket),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_currentUserProfile?.branch == 'All') ...[
                DropdownButtonFormField<String>(
                  initialValue: createBranch,
                  decoration: InputDecoration(
                    labelText: "Branch",
                    filled: true,
                    fillColor: AppTheme.bentoBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['All', ..._branchOptions]
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setCardState(() => createBranch = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bentoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_mockathonNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter session name")),
                      );
                      return;
                    }
                    if (_selectedMockathonDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a date")),
                      );
                      return;
                    }
                    final dateStr = "${_selectedMockathonDate!.year}-${_selectedMockathonDate!.month.toString().padLeft(2, '0')}-${_selectedMockathonDate!.day.toString().padLeft(2, '0')}";
                    final id = "${dateStr}_${createBranch.toLowerCase()}";

                    final mockathon = MockathonModel(
                      id: id,
                      name: _mockathonNameController.text.trim(),
                      date: _selectedMockathonDate!,
                      branch: createBranch,
                      isActive: false,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _dataService.createMockathon(mockathon);
                      _mockathonNameController.clear();
                      setCardState(() {
                        _selectedMockathonDate = null;
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Mockathon session created!")),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  child: const Text("CREATE SESSION", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMigrationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(
        color: Colors.white,
        radius: 24,
        shadow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Legacy Data Migration",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If you have older candidate or mark profiles without an associated Mockathon session, use this migration to bundle them into a 'Legacy Data' session.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.bentoJacket,
                side: const BorderSide(color: AppTheme.bentoJacket),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Migrate Legacy Data"),
                    content: Text("This will search all candidates in branch '$_selectedBranchFilter' who are not assigned to any Mockathon, bundle them under a new 'Legacy Data' session, and move their marks accordingly. Proceed?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Migrate"),
                      ),
                    ],
                  ),
                );
                if (!mounted) return;

                if (confirm == true) {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _dataService.migrateLegacyDataToMockathon(_selectedBranchFilter);
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Migration completed successfully!")),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text("Migration failed: $e")),
                    );
                  }
                }
              },
              child: const Text("MIGRATE LEGACY DATA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockathonsListCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(
        color: Colors.white,
        radius: 24,
        shadow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sessions List",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildFilterChip(
                "Branch",
                _selectedBranchFilter,
                ['All', ..._branchOptions],
                (val) => _updateBranchFilter(val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<MockathonModel>>(
            stream: _dataService.getMockathons(branch: _selectedBranchFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      "No mockathon sessions found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = list[index];
                  final formattedDate = "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (m.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "ACTIVE",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Date: $formattedDate | Branch: ${m.branch}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (!m.isActive) ...[
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await _dataService.updateActiveMockathon(m.id, branch: m.branch);
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Activated session: ${m.name}")),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            },
                            child: const Text("Activate"),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Session?"),
                                content: Text("Are you sure you want to delete '${m.name}'? This will unassign all students currently linked to this session and delete their marks records for this session."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                             if (confirm == true) {
                              try {
                                await _dataService.deleteMockathon(m.id);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Session deleted successfully")),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
