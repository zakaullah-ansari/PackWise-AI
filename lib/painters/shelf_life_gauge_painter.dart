import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';

/// Draws a semi-circular progress gauge representing how the AI-predicted
/// shelf life compares against the user's desired shelf life (`progress`
/// clamped to `[0, 1]`, where `1.0` means the prediction fully meets or
/// exceeds the target).
///
/// Used at the top of [ResultView] as the headline visualization.
///
/// Syllabus mapping: CustomPainter, Canvas arc drawing, trigonometry
/// (radians), gradients/shaders.
class ShelfLifeGaugePainter extends CustomPainter {
  ShelfLifeGaugePainter({
    required this.progress,
    this.strokeWidth = 14,
    this.trackColor = AppColors.glassFill,
  });

  /// 0.0–1.0 fraction of the desired shelf life achieved.
  final double progress;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width / 2, size.height) - strokeWidth / 2;
    if (radius <= 0) return;

    final Offset center = Offset(size.width / 2, size.height);
    const double startAngle = math.pi; // left side, pointing left
    const double sweepAngleTotal = math.pi; // half circle

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngleTotal,
      false,
      trackPaint,
    );

    final double clampedProgress = progress.clamp(0.0, 1.0);
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: <Color>[AppColors.primary, AppColors.secondary],
        startAngle: 0,
        endAngle: math.pi,
        transform: GradientRotation(math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngleTotal * clampedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ShelfLifeGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
  }
}
