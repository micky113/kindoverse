import 'dart:convert';
import 'package:flutter/material.dart';

/// Cross-platform network & data-URI image widget that uses
/// [WebHtmlElementStrategy.prefer] on Flutter Web so Firebase Cloud Storage
/// URLs render natively via browser `<img>` elements without failing on
/// CanvasKit XHR CORS restrictions.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context)? fallbackBuilder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _buildFallback(context);
    }

    if (trimmed.startsWith('data:image/')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1 && commaIndex + 1 < trimmed.length) {
        try {
          final bytes = base64Decode(trimmed.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (ctx, _, __) => _buildFallback(ctx),
          );
        } catch (_) {
          return _buildFallback(context);
        }
      }
    }

    return Image.network(
      trimmed,
      fit: fit,
      width: width,
      height: height,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        if (placeholderBuilder != null) {
          return placeholderBuilder!(ctx);
        }
        return Container(
          width: width,
          height: height,
          color: Colors.black.withValues(alpha: 0.05),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        );
      },
      errorBuilder: (ctx, _, __) => _buildFallback(ctx),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallbackBuilder != null) {
      return fallbackBuilder!(context);
    }
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE6F4F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color(0xFF0A6E5C),
      ),
    );
  }
}
