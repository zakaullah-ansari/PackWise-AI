import 'package:flutter/material.dart';
import 'package:packwise_ai/data/models/layer_spec.dart';

/// Draws a horizontal, proportionally-scaled cross-section of a (possibly
/// multi-layer) packaging film, one colored band per [LayerSpec].
///
/// Used on [MaterialDetailView] to visually teach that "a packaging
/// material" is often a laminate of several functional layers (structural,
/// barrier, sealant) rather than a single homogeneous sheet.
///
/// Syllabus mapping: CustomPainter, Canvas/Paint APIs, TextPainter,
/// proportional layout math.
class PackagingLayerPainter extends CustomPainter {
  PackagingLayerPainter({required this.layers});

  final List<LayerSpec> layers;

  @override
  void paint(Canvas canvas, Size size) {
    if (layers.isEmpty || size.width <= 0 || size.height <= 0) return;

    final double totalThickness =
        layers.fold<double>(0, (double sum, LayerSpec l) => sum + l.thicknessMicrons);
    if (totalThickness <= 0) return;

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double xOffset = 0;
    for (final LayerSpec layer in layers) {
      final double widthFraction = layer.thicknessMicrons / totalThickness;
      final double layerWidth = size.width * widthFraction;
      final Rect rect = Rect.fromLTWH(xOffset, 0, layerWidth, size.height);

      canvas.drawRect(rect, Paint()..color = layer.color);
      canvas.drawRect(rect, borderPaint);

      // Only draw the label if the band is wide enough to hold readable text.
      if (layerWidth > 46) {
        _drawLayerLabel(canvas, rect, layer);
      }

      xOffset += layerWidth;
    }
  }

  void _drawLayerLabel(Canvas canvas, Rect rect, LayerSpec layer) {
    final TextPainter thicknessPainter = TextPainter(
      text: TextSpan(
        text: '${layer.thicknessMicrons.toStringAsFixed(0)}µm',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 4);

    thicknessPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - thicknessPainter.width) / 2,
        rect.height / 2 - thicknessPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant PackagingLayerPainter oldDelegate) {
    return oldDelegate.layers.length != layers.length ||
        !_layersEqual(oldDelegate.layers, layers);
  }

  bool _layersEqual(List<LayerSpec> a, List<LayerSpec> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i].thicknessMicrons != b[i].thicknessMicrons || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }
}
