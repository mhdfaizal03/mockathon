enum UserRole { admin, interviewer, interviewee }

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String name; // Added name field

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name = '',
  });

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'role': role.name, 'name': name};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.interviewee,
      ),
    );
  }
}

class StudentModel extends UserModel {
  final String stack;
  final String randomId;
  final List<String> notifications;

  StudentModel({
    required String uid,
    required String email,
    required String name,
    required this.stack,
    required this.randomId,
    this.notifications = const [],
  }) : super(uid: uid, email: email, name: name, role: UserRole.interviewee);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'stack': stack,
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
      randomId: map['randomId'] ?? '',
      notifications: List<String>.from(map['notifications'] ?? []),
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

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.targetRole,
    this.type = 'info',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'targetRole': targetRole,
      'type': type,
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
    );
  }
}
