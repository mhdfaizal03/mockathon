import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/models/user_models.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        String randomId = _generateRandomId();
        StudentModel student = StudentModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          stack: stack,
          randomId: randomId,
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(student.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  // Register Interviewer/Admin (Helper for dev mostly, or separate admin flow)
  Future<void> registerStaff(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        UserModel user = UserModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          role: role,
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
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
}
