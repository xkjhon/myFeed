import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class AppImage extends StatelessWidget {
  static final Map<String, Uint8List> _base64Cache = {};

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppImage({
    Key? key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (src.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF1E1E1E),
        child: const Icon(Icons.image, color: Colors.grey, size: 20),
      );
    }

    // Handle Base64 Data URLs
    if (src.startsWith('data:')) {
      try {
        final commaIndex = src.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = src.substring(commaIndex + 1);
          final bytes = _base64Cache.putIfAbsent(base64Data, () => base64Decode(base64Data));
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        }
      } catch (e) {
        return _buildErrorWidget();
      }
    }

    // Handle Network URLs
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          );
        },
      );
    }

    // Handle Local Files
    try {
      final file = File(src);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    } catch (_) {}

    // Fallback if nothing else matches
    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A2D),
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
    );
  }
}
