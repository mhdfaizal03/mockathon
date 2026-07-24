import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/firebase_options.dart';
import 'dart:math';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register Student
  Future<void> registerStudent(
    String email,
    String password,
    String name,
    String stack,
    String remainStatus,
    String branch, {
    String? mockathonId,
  }) async {
    // Use a secondary app to prevent the primary app's auth state from changing
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempRegisterApp_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        String randomId = _generateRandomId();
        StudentModel student = StudentModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          branch: branch,
          stack: stack,
          remainStatus: remainStatus,
          randomId: randomId,
          hasCompletedOnboarding: false,
          mockathonId: mockathonId,
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(student.toMap());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Query user in Firestore by email
        final querySnap = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          final doc = querySnap.docs.first;
          final existingData = doc.data();
          final existingMockathonId = existingData['mockathonId'] as String?;
          final existingHistory = List<String>.from(existingData['mockathonHistory'] ?? []);
          
          if (existingMockathonId != null && 
              existingMockathonId != mockathonId && 
              !existingHistory.contains(existingMockathonId)) {
            existingHistory.add(existingMockathonId);
          }

          final student = StudentModel(
            uid: doc.id,
            email: email,
            name: name,
            branch: branch,
            stack: stack,
            remainStatus: remainStatus,
            randomId: existingData['randomId'] ?? _generateRandomId(),
            hasCompletedOnboarding: false,
            mockathonId: mockathonId,
            notifications: List<String>.from(existingData['notifications'] ?? []),
            cvUrl: existingData['cvUrl'],
            mockathonHistory: existingHistory,
          );

          await _firestore
              .collection('users')
              .doc(doc.id)
              .set(student.toMap(), SetOptions(merge: true));
          return;
        }
      }
      rethrow;
    } finally {
      await tempApp.delete();
    }
  }

  // Register Interviewer/Admin
  Future<void> registerStaff(
    String email,
    String password,
    String name,
    UserRole role,
    String branch,
  ) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempRegisterStaff_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        UserModel user = UserModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          branch: branch,
          role: role,
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toMap());
      }
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  String _generateRandomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<UserModel?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
