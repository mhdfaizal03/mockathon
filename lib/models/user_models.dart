enum UserRole { admin, interviewer, interviewee }

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String name;
  final bool hasCompletedOnboarding; // New flag

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name = '',
    this.hasCompletedOnboarding = true, // Default true for staff
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.name,
      'name': name,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? true,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.interviewee,
      ),
    );
  }
}

class StudentModel extends UserModel {
  final String stack;
  final String remainStatus;
  final String randomId;
  final List<String> notifications;

  StudentModel({
    required super.uid,
    required super.email,
    required super.name,
    required this.stack,
    required this.remainStatus,
    required this.randomId,
    this.notifications = const [],
    super.hasCompletedOnboarding = false,
  }) : super(role: UserRole.interviewee);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'stack': stack,
      'remainStatus': remainStatus,
      'randomId': randomId,
      'notifications': notifications,
    });
    return map;
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      stack: map['stack'] ?? '',
      remainStatus: map['remainStatus'] ?? 'Main Project',
      randomId: map['randomId'] ?? '',
      notifications: List<String>.from(map['notifications'] ?? []),
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
    );
  }
}

class MarkModel {
  final double aptitude;
  final String aptitudeFeedback;
  final double gd; // Group Discussion
  final String gdFeedback;
  final double hr;
  final String hrFeedback;

  MarkModel({
    this.aptitude = 0.0,
    this.aptitudeFeedback = '',
    this.gd = 0.0,
    this.gdFeedback = '',
    this.hr = 0.0,
    this.hrFeedback = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'aptitude': aptitude,
      'aptitudeFeedback': aptitudeFeedback,
      'gd': gd,
      'gdFeedback': gdFeedback,
      'hr': hr,
      'hrFeedback': hrFeedback,
    };
  }

  factory MarkModel.fromMap(Map<String, dynamic> map) {
    return MarkModel(
      aptitude: (map['aptitude'] ?? 0.0).toDouble(),
      aptitudeFeedback: map['aptitudeFeedback'] ?? '',
      gd: (map['gd'] ?? 0.0).toDouble(),
      gdFeedback: map['gdFeedback'] ?? '',
      hr: (map['hr'] ?? 0.0).toDouble(),
      // Fallback for old 'feedback' key if hrFeedback not present
      hrFeedback: map['hrFeedback'] ?? map['feedback'] ?? '',
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String
  targetRole; // 'all', 'interviewee', 'interviewer', or specific UID
  final String type; // 'info', 'alert', 'success'
  final double? minMarks;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.targetRole,
    this.type = 'info',
    this.minMarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'targetRole': targetRole,
      'type': type,
      'minMarks': minMarks,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      targetRole: map['targetRole'] ?? 'all',
      type: map['type'] ?? 'info',
      minMarks: map['minMarks']?.toDouble(),
    );
  }
}
