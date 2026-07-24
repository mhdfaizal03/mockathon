import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation of WebHelper.
class WebHelper {
  static void downloadFile({
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: type));
    final url = web.URL.createObjectURL(blob);
    downloadFromUrl(url, fileName);
    web.URL.revokeObjectURL(url);
  }

  static void downloadFromUrl(String url, String fileName) {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    anchor.setAttribute('download', fileName);
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
  }
}
