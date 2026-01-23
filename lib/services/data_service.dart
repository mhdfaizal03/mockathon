import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/models/user_models.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            if (role == 'interviewee' || data['role'] == 'interviewee') {
              return StudentModel.fromMap(data);
            }
            return UserModel.fromMap(data);
          }).toList();
        });
  }

  // Get all students
  Stream<List<StudentModel>> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'interviewee')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return StudentModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Get Student by UID
  Stream<StudentModel> getStudent(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      return StudentModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // Update Marks
  Future<void> updateMarks(String studentId, MarkModel marks) async {
    await _firestore.collection('marks').doc(studentId).set(marks.toMap());
  }

  // Get Marks
  Stream<MarkModel?> getMarks(String studentId) {
    return _firestore.collection('marks').doc(studentId).snapshots().map((doc) {
      if (doc.exists) {
        return MarkModel.fromMap(doc.data() as Map<String, dynamic>);
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
    );
    await docRef.set(newNote.toMap());
  }

  // Get Notifications Stream
  Stream<List<NotificationModel>> getNotifications(String userRole) {
    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .where((note) {
                // Filter by role or 'all'
                return note.targetRole == 'all' || note.targetRole == userRole;
              })
              .toList();
        });
  }

  // Get Settings (e.g., results published)
  Stream<bool> getResultsPublishedStream() {
    return _firestore
        .collection('settings')
        .doc('config')
        .snapshots()
        .map((doc) => doc.data()?['areResultsPublished'] ?? false);
  }

  // Update Settings
  Future<void> updateResultsPublished(bool isPublished) async {
    await _firestore.collection('settings').doc('config').set({
      'areResultsPublished': isPublished,
    }, SetOptions(merge: true));
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
