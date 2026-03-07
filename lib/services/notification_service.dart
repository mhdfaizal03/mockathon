import 'package:flutter/foundation.dart';

// FCM Removed. Notifications are now handled purely via Firestore Streams.
class NotificationService {
  Future<void> init() async {
    debugPrint("NotificationService (FCM) disabled.");
  }
}
