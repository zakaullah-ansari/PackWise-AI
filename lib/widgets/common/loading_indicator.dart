import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';

/// Branded loading state: a pulsing neon-teal ring plus an optional status
/// message, used while waiting on the Gemini API or a Firestore write.
///
/// Syllabus mapping: Stateless widgets, Animations (`flutter_animate`).
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 56,
          width: 56,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ).animate(onPlay: (AnimationController c) => c.repeat()).shimmer(
                duration: const Duration(milliseconds: 1400),
                color: AppColors.secondary,
              ),
        ),
        if (message != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ).animate(onPlay: (AnimationController c) => c.repeat(reverse: true)).fadeIn(
                duration: const Duration(milliseconds: 900),
              ),
        ],
      ],
    );
  }
}
