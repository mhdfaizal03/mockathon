import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockathon/core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mockathon/core/web_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResumeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadResume(
    Uint8List fileBytes,
    String originalFileName,
    String uid,
  ) async {
    try {
      final String fileName =
          '$uid/${DateTime.now().millisecondsSinceEpoch}_$originalFileName';

      // Remove old file if exists (optional but good for cleanup)
      // await _deleteOldResume(uid);

      await _supabase.storage
          .from(SupabaseConfig.resumeBucket)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.resumeBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload resume: $e');
    }
  }

  Future<void> updateStudentCvUrl(String uid, String url) async {
    try {
      await _firestore.collection('users').doc(uid).update({'cvUrl': url});
    } catch (e) {
      throw Exception('Failed to update student profile: $e');
    }
  }

  Future<void> launchResume(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch resume URL');
    }
  }

  void downloadResume(String url) {
    if (kIsWeb) {
      // Create an anchor element with the download attribute
      WebHelper.downloadFromUrl(url, 'resume.pdf');
    } else {
      // For mobile, launchUrl usually handles download intents or opens in browser which allows download
      launchResume(url);
    }
  }
}
