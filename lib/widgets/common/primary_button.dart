import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';

/// The app's primary call-to-action button: a teal→emerald gradient pill
/// with an optional leading icon and a built-in loading spinner state.
///
/// Centralizing this widget (instead of styling `ElevatedButton` ad-hoc on
/// every screen) keeps every primary action visually consistent with the
/// Dark Cyber-Glassmorphism design system.
///
/// Syllabus mapping: Widget composition, Layouts, stateless widgets,
/// conditional rendering.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Null disables the button entirely (in addition to [isLoading]).
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Whether the button should stretch to fill available width.
  final bool expand;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox(
              key: ValueKey<String>('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001014)),
              ),
            )
          : Row(
              key: const ValueKey<String>('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 20, color: const Color(0xFF001014)),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF001014),
                  ),
                ),
              ],
            ),
    );

    return Opacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            onTap: _isEnabled ? onPressed : null,
            child: Container(
              width: expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
