import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';

/// One comparable data point for [BarrierChartPainter]: a material's Oxygen
/// Transmission Rate and Water Vapor Transmission Rate.
class BarrierChartEntry {
  const BarrierChartEntry({
    required this.label,
    required this.otrCm3M2Day,
    required this.wvtrGM2Day,
  });

  final String label;
  final double otrCm3M2Day;
  final double wvtrGM2Day;
}

/// Draws a grouped bar chart comparing OTR (oxygen) and WVTR (moisture)
/// transmission rates across up to three recommended materials.
///
/// Real OTR/WVTR values can span several orders of magnitude in the same
/// chart (e.g. 0.05 for aluminum foil vs. 5000 for micro-perforated film),
/// so bar heights are scaled on a log10 axis — otherwise every material
/// except the single highest value would be visually flattened to zero.
///
/// Syllabus mapping: CustomPainter, logarithmic scaling, Canvas/TextPainter,
/// data visualization fundamentals.
class BarrierChartPainter extends CustomPainter {
  BarrierChartPainter({required this.entries});

  final List<BarrierChartEntry> entries;

  static const Color _otrColor = AppColors.primary;
  static const Color _wvtrColor = AppColors.secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const double labelHeight = 30;
    const double axisPadding = 8;
    final double chartHeight = size.height - labelHeight - axisPadding;
    if (chartHeight <= 0) return;

    final double maxRawValue = entries
        .expand((BarrierChartEntry e) => <double>[e.otrCm3M2Day, e.wvtrGM2Day])
        .fold<double>(1, (double max, double v) => v > max ? v : max);
    final double maxLog = _log10(maxRawValue + 1);

    final double groupWidth = size.width / entries.length;
    const double barWidth = 16;
    const double barGap = 6;

    for (int i = 0; i < entries.length; i++) {
      final BarrierChartEntry entry = entries[i];
      final double groupCenterX = groupWidth * i + groupWidth / 2;

      final double otrHeight = maxLog == 0
          ? 0
          : (_log10(entry.otrCm3M2Day + 1) / maxLog) * chartHeight;
      final double wvtrHeight = maxLog == 0
          ? 0
          : (_log10(entry.wvtrGM2Day + 1) / maxLog) * chartHeight;

      final Rect otrRect = Rect.fromLTWH(
        groupCenterX - barWidth - barGap / 2,
        axisPadding + (chartHeight - otrHeight),
        barWidth,
        otrHeight,
      );
      final Rect wvtrRect = Rect.fromLTWH(
        groupCenterX + barGap / 2,
        axisPadding + (chartHeight - wvtrHeight),
        barWidth,
        wvtrHeight,
      );

      _drawRoundedBar(canvas, otrRect, _otrColor);
      _drawRoundedBar(canvas, wvtrRect, _wvtrColor);

      _drawLabel(
        canvas,
        text: entry.label,
        center: Offset(groupCenterX, size.height - labelHeight / 2),
        maxWidth: groupWidth - 4,
      );
    }
  }

  void _drawRoundedBar(Canvas canvas, Rect rect, Color color) {
    if (rect.height <= 0) return;
    final RRect rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = color.withOpacity(0.85));
  }

  void _drawLabel(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double maxWidth,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  double _log10(double value) => value <= 0 ? 0 : math.log(value) / math.ln10;

  @override
  bool shouldRepaint(covariant BarrierChartPainter oldDelegate) {
    return oldDelegate.entries.length != entries.length;
  }
}
