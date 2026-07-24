import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/auth_service.dart';

class DataService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Get App Name Stream
  Stream<String> getAppNameStream() {
    return _firestore
        .collection('settings')
        .doc('config_global')
        .snapshots()
        .map((doc) => (doc.data()?['appName'] as String?) ?? 'Mockathon');
  }

  // Update App Name
  Future<void> updateAppName(String newName) async {
    await _firestore.collection('settings').doc('config_global').set({
      'appName': newName,
    }, SetOptions(merge: true));
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(
    String role, {
    String? branch,
    String? mockathonId,
  }) {
    final CollectionReference<Map<String, dynamic>> query = _firestore
        .collection('users');

    // If 'staff', fetch both admin and interviewer, otherwise filter by role
    Query<Map<String, dynamic>> firestoreQuery;
    if (role == 'staff') {
      firestoreQuery = query.where('role', whereIn: ['admin', 'interviewer']);
    } else {
      firestoreQuery = query.where('role', isEqualTo: role);
    }

    if (role == 'interviewee' && mockathonId != null && mockathonId != 'All') {
      firestoreQuery = firestoreQuery.where(
        'mockathonId',
        isEqualTo: mockathonId,
      );
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
  Stream<List<StudentModel>> getStudents({
    String? branch,
    String? mockathonId,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _firestore
        .collection('users')
        .where('role', isEqualTo: 'interviewee');

    if (mockathonId != null && mockathonId != 'All') {
      firestoreQuery = firestoreQuery.where(
        'mockathonId',
        isEqualTo: mockathonId,
      );
    }

    return firestoreQuery.snapshots().map((snapshot) {
      final students = snapshot.docs.map((doc) {
        return StudentModel.fromMap(doc.data());
      }).toList();

      if (branch != null && branch != 'All') {
        return students.where((s) => s.branch.trim() == branch.trim()).toList();
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
  Future<void> updateMarks(
    String studentId,
    MarkModel marks, {
    String? mockathonId,
  }) async {
    String docId = studentId;
    if (mockathonId != null && mockathonId.isNotEmpty) {
      docId = '${studentId}_$mockathonId';
    } else {
      final doc = await _firestore.collection('users').doc(studentId).get();
      final mId = doc.data()?['mockathonId'] as String?;
      if (mId != null && mId.isNotEmpty) {
        docId = '${studentId}_$mId';
      }
    }
    await _firestore.collection('marks').doc(docId).set(marks.toMap());
  }

  // Get Marks
  Stream<MarkModel?> getMarks(String studentId, {String? mockathonId}) {
    if (mockathonId != null && mockathonId.isNotEmpty) {
      return _firestore
          .collection('marks')
          .doc('${studentId}_$mockathonId')
          .snapshots()
          .map((doc) => doc.exists ? MarkModel.fromMap(doc.data()!) : null);
    }

    // Stream profile dynamically to get the current mockathonId for the student
    return _firestore
        .collection('users')
        .doc(studentId)
        .snapshots()
        .asyncExpand((userDoc) {
          final userData = userDoc.data();
          final mId = userData?['mockathonId'] as String?;
          if (mId == null || mId.isEmpty) {
            // Fallback for legacy database entries
            return _firestore
                .collection('marks')
                .doc(studentId)
                .snapshots()
                .map(
                  (doc) => doc.exists ? MarkModel.fromMap(doc.data()!) : null,
                );
          }
          return _firestore
              .collection('marks')
              .doc('${studentId}_$mId')
              .snapshots()
              .map((doc) => doc.exists ? MarkModel.fromMap(doc.data()!) : null);
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
  Stream<Map<String, MarkModel>> getAllMarksStream({String? mockathonId}) {
    return _firestore.collection('marks').snapshots().map((snapshot) {
      final map = <String, MarkModel>{};
      for (var doc in snapshot.docs) {
        final id = doc.id;
        final data = doc.data();
        if (id.contains('_')) {
          final parts = id.split('_');
          final studentId = parts[0];
          final mId = parts.sublist(1).join('_');
          if (mockathonId == null ||
              mockathonId == 'All' ||
              mId == mockathonId) {
            map[studentId] = MarkModel.fromMap(data);
          }
        } else {
          // Legacy marks without mockathon suffix
          if (mockathonId == null || mockathonId == 'All') {
            map[id] = MarkModel.fromMap(data);
          }
        }
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

  // Get all mockathons
  Stream<List<MockathonModel>> getMockathons({String? branch}) {
    return _firestore
        .collection('mockathons')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return MockathonModel.fromMap(doc.data());
          }).toList();
          if (branch != null && branch != 'All') {
            return list
                .where(
                  (m) =>
                      m.branch == 'All' ||
                      m.branch.trim().toLowerCase() ==
                          branch.trim().toLowerCase(),
                )
                .toList();
          }
          return list;
        });
  }

  // Create mockathon
  Future<void> createMockathon(MockathonModel mockathon) async {
    await _firestore
        .collection('mockathons')
        .doc(mockathon.id)
        .set(mockathon.toMap());
  }

  // Get active mockathon ID stream
  Stream<String?> getActiveMockathonIdStream({required String branch}) {
    final stabilizedBranch = branch.trim().toLowerCase();
    if (stabilizedBranch == 'all') {
      return _firestore
          .collection('settings')
          .doc('active_mockathon')
          .snapshots()
          .map((doc) => doc.data()?['activeMockathonId'] as String?);
    }

    return _firestore
        .collection('settings')
        .doc('active_mockathon_$stabilizedBranch')
        .snapshots()
        .asyncExpand((branchDoc) {
          final branchActiveId =
              branchDoc.data()?['activeMockathonId'] as String?;
          if (branchActiveId != null && branchActiveId.isNotEmpty) {
            return Stream.value(branchActiveId);
          }
          return _firestore
              .collection('settings')
              .doc('active_mockathon')
              .snapshots()
              .map((allDoc) => allDoc.data()?['activeMockathonId'] as String?);
        });
  }

  // Update active mockathon
  Future<void> updateActiveMockathon(
    String mockathonId, {
    required String branch,
  }) async {
    final stabilizedBranch = branch.trim().toLowerCase();
    final docId = stabilizedBranch == 'all'
        ? 'active_mockathon'
        : 'active_mockathon_$stabilizedBranch';

    // 1. Update settings document
    await _firestore.collection('settings').doc(docId).set({
      'activeMockathonId': mockathonId,
    }, SetOptions(merge: true));

    // 2. Update status flags inside collection
    final batch = _firestore.batch();
    final snap = await _firestore.collection('mockathons').get();

    // Find the branch of the target mockathon being activated
    String targetBranch = 'All';
    for (var doc in snap.docs) {
      if (doc.id == mockathonId) {
        targetBranch = doc.data()['branch'] ?? 'All';
        break;
      }
    }
    final targetBranchLower = targetBranch.trim().toLowerCase();

    for (var doc in snap.docs) {
      final data = doc.data();
      final mBranch = (data['branch'] ?? 'All').toString().trim().toLowerCase();
      if (mBranch == targetBranchLower) {
        batch.update(doc.reference, {'isActive': doc.id == mockathonId});
      }
    }
    await batch.commit();
  }

  // Delete mockathon
  Future<void> deleteMockathon(String mockathonId) async {
    final batch = _firestore.batch();

    // 1. Delete mockathon document
    final mockathonRef = _firestore.collection('mockathons').doc(mockathonId);
    batch.delete(mockathonRef);

    // 2. Clear settings for active mockathon references if they match this mockathon ID
    final settingsSnap = await _firestore.collection('settings').get();
    for (var doc in settingsSnap.docs) {
      if (doc.data()['activeMockathonId'] == mockathonId) {
        batch.update(doc.reference, {'activeMockathonId': FieldValue.delete()});
      }
    }

    // 3. Clear mockathonId from users/students who are assigned to this mockathon
    final studentsSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'interviewee')
        .where('mockathonId', isEqualTo: mockathonId)
        .get();
    for (var doc in studentsSnap.docs) {
      batch.update(doc.reference, {'mockathonId': FieldValue.delete()});
    }

    // 4. Delete marks associated with this mockathon
    final marksSnap = await _firestore.collection('marks').get();
    for (var doc in marksSnap.docs) {
      if (doc.id.endsWith('_$mockathonId')) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  // Migrate legacy data
  Future<void> migrateLegacyDataToMockathon(String branch) async {
    final batch = _firestore.batch();
    final legacyMockathonId =
        'legacy_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create a "Legacy Data" Mockathon
    final newMockathon = MockathonModel(
      id: legacyMockathonId,
      name: 'Legacy Data',
      date: DateTime.now(),
      isActive: false,
      branch: branch,
    );
    batch.set(
      _firestore.collection('mockathons').doc(legacyMockathonId),
      newMockathon.toMap(),
    );

    // 2. Find legacy students
    final usersSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'interviewee')
        .get();
    for (var doc in usersSnap.docs) {
      final data = doc.data();
      final mockathonId = data['mockathonId'] as String?;
      final userBranch = data['branch'] as String? ?? 'All';

      if ((mockathonId == null || mockathonId.isEmpty) &&
          (branch == 'All' || branch == userBranch)) {
        batch.update(doc.reference, {'mockathonId': legacyMockathonId});

        // 3. Migrate their marks
        final marksDoc = await _firestore
            .collection('marks')
            .doc(doc.id)
            .get();
        if (marksDoc.exists) {
          final markData = marksDoc.data()!;
          batch.set(
            _firestore
                .collection('marks')
                .doc('${doc.id}_$legacyMockathonId'),
            markData,
          );
          batch.delete(marksDoc.reference);
        }
      }
    }

    await batch.commit();
  }
}
