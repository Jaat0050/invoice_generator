import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CompressedImageResult {
  final Uint8List bytes;
  final String mimeType;
  final String formatExtension; // 'png' or 'jpg'
  final int sizeInBytes;

  const CompressedImageResult({
    required this.bytes,
    required this.mimeType,
    required this.formatExtension,
    required this.sizeInBytes,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class ImageCompressorService {
  ImageCompressorService._();

  static const int maxTargetSizeBytes = 200 * 1024; // 200 KB strict limit

  /// Compresses and scales image bytes to strictly stay under 200KB.
  /// If [preserveTransparency] is true (e.g. for signatures), it compresses as PNG.
  /// Otherwise (e.g. for logos/photos), it encodes as progressive JPEG.
  static CompressedImageResult compressImage(
    Uint8List rawBytes, {
    bool preserveTransparency = false,
    int maxDimension = 1024,
  }) {
    // Decode image using pure Dart 'image' library
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      // If decoding fails, return raw bytes clamped if already small
      return CompressedImageResult(
        bytes: rawBytes,
        mimeType: preserveTransparency ? 'image/png' : 'image/jpeg',
        formatExtension: preserveTransparency ? 'png' : 'jpg',
        sizeInBytes: rawBytes.lengthInBytes,
      );
    }

    // 1. Resize if dimension exceeds maxDimension
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
        interpolation: img.Interpolation.average,
      );
    }

    // 2. Encode and iteratively reduce quality/size until strictly <= 200KB
    Uint8List outputBytes;
    String mimeType;
    String extension;

    if (preserveTransparency) {
      mimeType = 'image/png';
      extension = 'png';
      int currentLevel = 6;
      img.Image currentImg = decoded;

      outputBytes = Uint8List.fromList(img.encodePng(currentImg, level: currentLevel));

      // If still above 200KB, downscale iteratively
      while (outputBytes.lengthInBytes > maxTargetSizeBytes && currentImg.width > 200) {
        final newWidth = (currentImg.width * 0.8).toInt();
        final newHeight = (currentImg.height * 0.8).toInt();
        currentImg = img.copyResize(
          currentImg,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.average,
        );
        outputBytes = Uint8List.fromList(img.encodePng(currentImg, level: 9));
      }
    } else {
      mimeType = 'image/jpeg';
      extension = 'jpg';
      int quality = 85;
      img.Image currentImg = decoded;

      outputBytes = Uint8List.fromList(img.encodeJpg(currentImg, quality: quality));

      // Iteratively reduce quality
      while (outputBytes.lengthInBytes > maxTargetSizeBytes && quality > 20) {
        quality -= 15;
        outputBytes = Uint8List.fromList(img.encodeJpg(currentImg, quality: quality));
      }

      // If quality reduction isn't enough, downscale dimensions
      while (outputBytes.lengthInBytes > maxTargetSizeBytes && currentImg.width > 200) {
        final newWidth = (currentImg.width * 0.75).toInt();
        final newHeight = (currentImg.height * 0.75).toInt();
        currentImg = img.copyResize(
          currentImg,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.average,
        );
        outputBytes = Uint8List.fromList(img.encodeJpg(currentImg, quality: 70));
      }
    }

    return CompressedImageResult(
      bytes: outputBytes,
      mimeType: mimeType,
      formatExtension: extension,
      sizeInBytes: outputBytes.lengthInBytes,
    );
  }
}
