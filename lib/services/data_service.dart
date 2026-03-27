import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';

class DataService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(String role, {String? branch}) {
    final CollectionReference<Map<String, dynamic>> query = _firestore
        .collection('users');

    // If 'staff', fetch both admin and interviewer, otherwise filter by role
    Query<Map<String, dynamic>> firestoreQuery;
    if (role == 'staff') {
      firestoreQuery = query.where('role', whereIn: ['admin', 'interviewer']);
    } else {
      firestoreQuery = query.where('role', isEqualTo: role);
    }

    return firestoreQuery.snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        if (role == 'interviewee' ||
            (data['role'] as String?) == 'interviewee') {
          return StudentModel.fromMap(data);
        }
        return UserModel.fromMap(data);
      }).toList();

      if (branch != null && branch != 'All') {
        return users.where((u) => u.branch.trim() == branch.trim()).toList();
      }
      return users;
    });
  }

  // Get all students
  Stream<List<StudentModel>> getStudents({String? branch}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'interviewee')
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs.map((doc) {
            return StudentModel.fromMap(doc.data());
          }).toList();

          if (branch != null && branch != 'All') {
            return students
                .where((s) => s.branch.trim() == branch.trim())
                .toList();
          }
          return students;
        });
  }

  // Get Student by UID
  Stream<StudentModel> getStudent(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        // Return a dummy student model if profile not found to prevent crashes
        return StudentModel(
          uid: uid,
          email: '',
          name: 'Loading...',
          branch: 'Kozhikode',
          stack: '',
          remainStatus: '',
          randomId: '',
        );
      }
      return StudentModel.fromMap(data);
    });
  }

  // Update Marks
  Future<void> updateMarks(String studentId, MarkModel marks) async {
    await _firestore.collection('marks').doc(studentId).set(marks.toMap());
  }

  // Get Marks
  Stream<MarkModel?> getMarks(String studentId) {
    return _firestore.collection('marks').doc(studentId).snapshots().map((doc) {
      final data = doc.data();
      if (data != null) {
        return MarkModel.fromMap(data);
      }
      return null;
    });
  }

  // Fetch all Marks (One-time)
  Future<List<MarkModel>> fetchAllMarks() async {
    final snapshot = await _firestore.collection('marks').get();
    return snapshot.docs.map((doc) {
      return MarkModel.fromMap(doc.data());
    }).toList();
  }

  // Stream all Marks for Dashboard filtering
  Stream<Map<String, MarkModel>> getAllMarksStream() {
    return _firestore.collection('marks').snapshots().map((snapshot) {
      final map = <String, MarkModel>{};
      for (var doc in snapshot.docs) {
        map[doc.id] = MarkModel.fromMap(doc.data());
      }
      return map;
    });
  }

  // Broadcast Notification
  Future<void> broadcastNotification(NotificationModel note) async {
    final docRef = _firestore.collection('notifications').doc();
    final newNote = NotificationModel(
      id: docRef.id,
      title: note.title,
      message: note.message,
      timestamp: DateTime.now(),
      targetRole: note.targetRole,
      type: note.type,
      minMarks: note.minMarks,
      branch: note.branch, // Add branch forwarding
    );
    await docRef.set(newNote.toMap());
  }

  // Get Notifications Stream
  Stream<List<NotificationModel>> getNotifications(
    String userRole, {
    String? branch,
  }) async* {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    String? enforcedBranch = branch;
    String? currentUid = currentUser?.uid;

    if (currentUser != null) {
      final profile = await authService.getUserProfile(currentUser.uid);
      if (profile != null && profile.branch != 'All') {
        enforcedBranch = profile.branch;
      }
    }

    yield* _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .where((note) {
                // Filter by role OR specific UID (for DMs)
                bool roleMatch =
                    (note.targetRole == 'all' ||
                    note.targetRole == userRole ||
                    (currentUid != null && note.targetRole == currentUid));

                // Filter by explicit branch or global branch targeting
                bool branchMatch =
                    (note.branch == 'All' ||
                    enforcedBranch == 'All' ||
                    note.branch == enforcedBranch);

                return roleMatch && branchMatch;
              })
              .toList();
        });
  }

  // Get Settings (e.g., results published)
  Stream<bool> getResultsPublishedStream({String branch = 'All'}) {
    final stabilizedBranch = branch.trim().toLowerCase();
    return _firestore
        .collection('settings')
        .doc('config_$stabilizedBranch')
        .snapshots()
        .map((doc) => doc.data()?['areResultsPublished'] ?? false);
  }

  // Update Settings
  Future<void> updateResultsPublished(
    bool isPublished, {
    String branch = 'All',
  }) async {
    final stabilizedBranch = branch.trim().toLowerCase();
    await _firestore.collection('settings').doc('config_$stabilizedBranch').set(
      {'areResultsPublished': isPublished},
      SetOptions(merge: true),
    );
  }

  // Update User Details
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  // Delete User
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> completeOnboarding(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'hasCompletedOnboarding': true,
    });
  }
}
