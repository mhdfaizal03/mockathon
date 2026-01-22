import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // 2. Get and Save Token
      String? token = await _getToken();
      if (token != null) {
        if (kDebugMode) print("FCM Token: $token");
        _auth.authStateChanges().listen((user) {
          if (user != null) {
            _saveToken(user.uid, token);
          }
        });
      }

      // 3. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        User? user = _auth.currentUser;
        if (user != null) {
          _saveToken(user.uid, newToken);
        }
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print(
              'Message also contained a notification: ${message.notification}',
            );
          }
        }
      });
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        return await _firebaseMessaging.getToken(
          // TODO: REPLACE THIS WITH YOUR ACTUAL VAPID KEY FROM FIREBASE CONSOLE -> PROJECT SETTINGS -> CLOUD MESSAGING -> WEB PUSH CERTIFICATES
          vapidKey:
              "BGQDGUsDeq6cBZlNulOQpURRE5gskPZJ4csKHydNIRA9jHrS-6LX3WiQMO95tjEXVw0A-XGBkjf9nNilM6PKQuk",
        );
      } else {
        return await _firebaseMessaging.getToken();
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({'fcmToken': token});
      debugPrint("FCM Token saved for user $uid");
    } catch (e) {
      // If document doesn't exist or other error
      debugPrint("Error saving FCM token: $e");
    }
  }
}
