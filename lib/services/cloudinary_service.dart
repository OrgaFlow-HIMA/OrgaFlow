import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadException implements Exception {
  final String message;
  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  final String? apiKey;
  final String? apiSecret;

  CloudinaryService({
    String? cloudName,
    String? uploadPreset,
    String? apiKey,
    String? apiSecret,
  }) : cloudName =
           cloudName ?? dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim() ?? '',
       uploadPreset =
           uploadPreset ?? dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim() ?? '',
       apiKey = apiKey ?? dotenv.env['CLOUDINARY_API_KEY']?.trim(),
       apiSecret = apiSecret ?? dotenv.env['CLOUDINARY_API_SECRET']?.trim();

  /// Mengunggah file (PDF / Gambar) langsung ke Cloudinary (Unsigned Preset).
  /// Mendukung byte data sehingga bekerja mulus di Android, iOS, maupun Web.
  Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String? folder,
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw const CloudinaryUploadException(
        'Konfigurasi Cloudinary belum lengkap. Periksa CLOUDINARY_CLOUD_NAME dan CLOUDINARY_UPLOAD_PRESET di file .env.',
      );
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset;

    if (folder != null && folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }

    if (apiKey != null &&
        apiKey!.isNotEmpty &&
        apiKey != 'your_cloudinary_api_key') {
      request.fields['api_key'] = apiKey!;
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    );

    request.files.add(multipartFile);

    try {
      debugPrint(
        '[OrgaFlow Cloudinary] Mengunggah $fileName ke instance $cloudName...',
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl == null || secureUrl.isEmpty) {
          throw const CloudinaryUploadException(
            'Cloudinary tidak mengembalikan tautan secure_url.',
          );
        }
        debugPrint('[OrgaFlow Cloudinary] Berhasil upload! URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint(
          '[OrgaFlow Cloudinary ERROR] Response ${response.statusCode}: ${response.body}',
        );
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final msg = errorData['error']?['message'] ?? response.body;
          throw CloudinaryUploadException('Gagal upload ke Cloudinary: $msg');
        } catch (e) {
          if (e is CloudinaryUploadException) rethrow;
          throw CloudinaryUploadException(
            'Gagal upload ke Cloudinary (HTTP ${response.statusCode}).',
          );
        }
      }
    } catch (e) {
      if (e is CloudinaryUploadException) rethrow;
      debugPrint('[OrgaFlow Cloudinary Exception] $e');
      throw CloudinaryUploadException(
        'Terjadi kendala koneksi saat mengunggah berkas: $e',
      );
    }
  }
}
