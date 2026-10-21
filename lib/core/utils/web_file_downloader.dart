import 'dart:typed_data';

import 'web_file_downloader_stub.dart'
    if (dart.library.html) 'web_file_downloader_web.dart';

void downloadFileWebPlatform(Uint8List bytes, String filename, String mimeType) {
  downloadFileWeb(bytes, filename, mimeType);
}
