import 'dart:typed_data';

/// Stub implementation of WebHelper for non-web platforms.
class WebHelper {
  static void downloadFile({
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) {
    // No-op on non-web
  }

  static void downloadFromUrl(String url, String fileName) {
    // No-op on non-web
  }
}
