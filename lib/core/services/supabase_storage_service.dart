import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'image_compressor_service.dart';

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService();
});

class SupabaseStorageService {
  static const String bucketName = 'business-assets';

  SupabaseClient? get _supabase {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Uploads company logo to Supabase Storage.
  /// Guarantees EXACTLY ONE logo file per user: replaces/overwrites existing file
  /// and cleans up any legacy files for this user to minimize bucket storage.
  Future<String> uploadLogo(Uint8List rawBytes) async {
    // 1. Compress image to strictly <= 200KB JPEG
    final compressed = ImageCompressorService.compressImage(
      rawBytes,
      preserveTransparency: false,
      maxDimension: 1024,
    );

    debugPrint('Logo compressed from ${rawBytes.lengthInBytes} B to ${compressed.formattedSize}');

    final sb = _supabase;
    final user = sb?.auth.currentUser;

    if (sb == null || user == null) {
      // Fallback to data URI if offline / demo mode
      final base64Str = base64Encode(compressed.bytes);
      return 'data:${compressed.mimeType};base64,$base64Str';
    }

    try {
      final userFolder = 'users/${user.id}';
      final fileName = 'logo.${compressed.formatExtension}';
      final storagePath = '$userFolder/$fileName';

      // 1. Delete previous logo files from storage before adding the new one
      try {
        final existingFiles = await sb.storage.from(bucketName).list(path: userFolder);
        final oldLogos = existingFiles
            .where((f) => f.name.startsWith('logo'))
            .map((f) => '$userFolder/${f.name}')
            .toList();
        if (oldLogos.isNotEmpty) {
          await sb.storage.from(bucketName).remove(oldLogos);
        }
      } catch (listErr) {
        debugPrint('Notice deleting previous logo file: $listErr');
      }

      // 2. Upload the new logo
      await sb.storage.from(bucketName).uploadBinary(
            storagePath,
            compressed.bytes,
            fileOptions: FileOptions(
              contentType: compressed.mimeType,
              upsert: true,
            ),
          );

      final basePublicUrl = sb.storage.from(bucketName).getPublicUrl(storagePath);
      final publicUrl = '$basePublicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase logo upload error: $e');
      final base64Str = base64Encode(compressed.bytes);
      return 'data:${compressed.mimeType};base64,$base64Str';
    }
  }

  /// Uploads authorized signature to Supabase Storage.
  /// Guarantees EXACTLY ONE signature file per user: deletes any previous signature
  /// before saving the new one.
  Future<String> uploadSignature(Uint8List rawBytes) async {
    // 1. Compress image to strictly <= 200KB transparent PNG
    final compressed = ImageCompressorService.compressImage(
      rawBytes,
      preserveTransparency: true,
      maxDimension: 800,
    );

    debugPrint('Signature compressed from ${rawBytes.lengthInBytes} B to ${compressed.formattedSize}');

    final sb = _supabase;
    final user = sb?.auth.currentUser;

    if (sb == null || user == null) {
      final base64Str = base64Encode(compressed.bytes);
      return 'data:${compressed.mimeType};base64,$base64Str';
    }

    try {
      final userFolder = 'users/${user.id}';
      final fileName = 'signature.${compressed.formatExtension}';
      final storagePath = '$userFolder/$fileName';

      // 1. Delete previous signature files from storage before adding the new one
      try {
        final existingFiles = await sb.storage.from(bucketName).list(path: userFolder);
        final oldSignatures = existingFiles
            .where((f) => f.name.startsWith('signature'))
            .map((f) => '$userFolder/${f.name}')
            .toList();
        if (oldSignatures.isNotEmpty) {
          await sb.storage.from(bucketName).remove(oldSignatures);
        }
      } catch (listErr) {
        debugPrint('Notice deleting previous signature file: $listErr');
      }

      // 2. Upload the new signature
      await sb.storage.from(bucketName).uploadBinary(
            storagePath,
            compressed.bytes,
            fileOptions: FileOptions(
              contentType: compressed.mimeType,
              upsert: true,
            ),
          );

      final basePublicUrl = sb.storage.from(bucketName).getPublicUrl(storagePath);
      // Append timestamp query parameter to bust client image caching
      final publicUrl = '$basePublicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase signature upload error: $e');
      final base64Str = base64Encode(compressed.bytes);
      return 'data:${compressed.mimeType};base64,$base64Str';
    }
  }

  /// Deletes the user's logo file from Supabase Storage bucket
  Future<void> deleteLogo() async {
    final sb = _supabase;
    final user = sb?.auth.currentUser;
    if (sb == null || user == null) return;

    try {
      final userFolder = 'users/${user.id}';
      final files = await sb.storage.from(bucketName).list(path: userFolder);
      final logoFiles = files
          .where((f) => f.name.startsWith('logo'))
          .map((f) => '$userFolder/${f.name}')
          .toList();
      if (logoFiles.isNotEmpty) {
        await sb.storage.from(bucketName).remove(logoFiles);
      }
    } catch (e) {
      debugPrint('Error deleting logo from storage: $e');
    }
  }

  /// Deletes the user's signature file from Supabase Storage bucket
  Future<void> deleteSignature() async {
    final sb = _supabase;
    final user = sb?.auth.currentUser;
    if (sb == null || user == null) return;

    try {
      final userFolder = 'users/${user.id}';
      final files = await sb.storage.from(bucketName).list(path: userFolder);
      final sigFiles = files
          .where((f) => f.name.startsWith('signature'))
          .map((f) => '$userFolder/${f.name}')
          .toList();
      if (sigFiles.isNotEmpty) {
        await sb.storage.from(bucketName).remove(sigFiles);
      }
    } catch (e) {
      debugPrint('Error deleting signature from storage: $e');
    }
  }
}
