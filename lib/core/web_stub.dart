// Stub for dart:html classes to allow compilation on non-web platforms (e.g., tests)

class Blob {
  Blob(List<dynamic> blobParts, [String? type, String? endings]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String? href;
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}
