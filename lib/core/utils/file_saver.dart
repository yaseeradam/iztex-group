import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'web_file_downloader.dart';

class FileSaver {
  /// Saves / shares PDF bytes cross-platform (Web, iOS, Android, macOS, Windows).
  static Future<void> savePdf(BuildContext context, String filename, List<int> bytes) async {
    final u8bytes = Uint8List.fromList(bytes);
    try {
      // On Web, iOS, and Android, Printing.sharePdf provides the cleanest native experience:
      // - Web (Safari / Chrome): downloads the PDF file with the specified filename
      // - iOS: opens native UIActivityViewController with AirDrop, Save to Files, Print, Share
      // - Android: opens Android Sharesheet
      final shared = await Printing.sharePdf(
        bytes: u8bytes,
        filename: filename,
      );

      if (!shared && kIsWeb) {
        // Fallback for Web browsers: opens PDF layout/preview dialog where user can save or print
        await Printing.layoutPdf(
          onLayout: (format) async => u8bytes,
          name: filename,
        );
      }
    } catch (e) {
      // Secondary fallback using in-memory XFile.fromData (no path_provider / temporary file required)
      try {
        final box = context.mounted ? (context.findRenderObject() as RenderBox?) : null;
        final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

        final xFile = XFile.fromData(
          u8bytes,
          name: filename,
          mimeType: 'application/pdf',
        );
        final result = await Share.shareXFiles([xFile], text: filename, sharePositionOrigin: origin);
        if (kIsWeb && result.status == ShareResultStatus.unavailable) {
          downloadFileWebPlatform(u8bytes, filename, 'application/pdf');
        }
      } catch (fallbackError) {
        if (kIsWeb) {
          downloadFileWebPlatform(u8bytes, filename, 'application/pdf');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  /// Saves and shares arbitrary bytes (JSON, images, etc.) cross-platform without path_provider.
  static Future<void> saveFileBytes(
    BuildContext context,
    Uint8List bytes,
    String filename, {
    String mimeType = 'application/octet-stream',
    String? shareText,
    String? subject,
  }) async {
    try {
      final box = context.mounted ? (context.findRenderObject() as RenderBox?) : null;
      final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      final xFile = XFile.fromData(
        bytes,
        name: filename,
        mimeType: mimeType,
      );

      bool sharedSuccessfully = false;
      try {
        final result = await Share.shareXFiles(
          [xFile],
          text: shareText ?? filename,
          subject: subject,
          sharePositionOrigin: origin,
        );
        if (result.status != ShareResultStatus.unavailable) {
          sharedSuccessfully = true;
        }
      } catch (e) {
        debugPrint('Share.shareXFiles error: $e');
      }

      // If Web Share API is unavailable on this browser or threw an error, fallback to direct browser download
      if (!sharedSuccessfully && kIsWeb) {
        downloadFileWebPlatform(bytes, filename, mimeType);
      }
    } catch (e) {
      if (kIsWeb) {
        downloadFileWebPlatform(bytes, filename, mimeType);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to export file: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  /// Saves raw image bytes and shares without requiring path_provider.
  static Future<void> saveImageBytes(BuildContext context, Uint8List bytes, String filename) async {
    await saveFileBytes(
      context,
      bytes,
      filename,
      mimeType: 'image/png',
    );
  }

  /// Saves JSON data bytes and shares without requiring path_provider.
  static Future<void> saveJson(
    BuildContext context,
    String filename,
    Uint8List bytes, {
    String? shareText,
    String? subject,
  }) async {
    await saveFileBytes(
      context,
      bytes,
      filename,
      mimeType: 'application/json',
      shareText: shareText,
      subject: subject,
    );
  }

  /// Shares an image file safely with iPad / popover origin support.
  static Future<void> saveImage(BuildContext context, dynamic file) async {
    try {
      final box = context.mounted ? (context.findRenderObject() as RenderBox?) : null;
      final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
      final path = file is String ? file : (file as dynamic).path as String;
      final name = path.split('/').last;

      await Share.shareXFiles([XFile(path)], text: name, sharePositionOrigin: origin);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to share image: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
