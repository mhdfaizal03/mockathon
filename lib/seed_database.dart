import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final List<Map<String, dynamic>> initialAccounts = [
    // Super Admin
    {'email': 'superadmin@mockathon.com', 'role': 'admin', 'branch': 'All'},

    // Admins
    {
      'email': 'admin.kozhikode@mockathon.com',
      'role': 'admin',
      'branch': 'Kozhikode',
    },
    {
      'email': 'admin.palakkad@mockathon.com',
      'role': 'admin',
      'branch': 'Palakkad',
    },
    {
      'email': 'admin.perinthalmanna@mockathon.com',
      'role': 'admin',
      'branch': 'Perinthalmanna',
    },
    {'email': 'admin.kochi@mockathon.com', 'role': 'admin', 'branch': 'Kochi'},

    // Interviewers
    {
      'email': 'interviewer.kozhikode@mockathon.com',
      'role': 'interviewer',
      'branch': 'Kozhikode',
    },
    {
      'email': 'interviewer.palakkad@mockathon.com',
      'role': 'interviewer',
      'branch': 'Palakkad',
    },
    {
      'email': 'interviewer.perinthalmanna@mockathon.com',
      'role': 'interviewer',
      'branch': 'Perinthalmanna',
    },
    {
      'email': 'interviewer.kochi@mockathon.com',
      'role': 'interviewer',
      'branch': 'Kochi',
    },
  ];

  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  for (final acc in initialAccounts) {
    try {
      final email = acc['email'] as String;
      final role = acc['role'] as String;
      final branch = acc['branch'] as String;
      final password = 'mockathon123'; // Default password

      // Attempt to register
      final UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email,
          'role': role,
          'branch': branch,
          'name': '${branch} ${role.toUpperCase()}',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Created $role for $branch ($email)');
      }
    } catch (e) {
      print('Skipped ${acc["email"]}: $e');
    }
  }

  print('Database seeding complete!');
}
