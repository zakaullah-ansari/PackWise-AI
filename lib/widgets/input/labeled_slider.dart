import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';

/// A [Slider] paired with a label and a live, monospace-formatted value
/// readout — used throughout [InputFormView] for every continuous numeric
/// commodity property (moisture, fat, pH, respiration rate, temperature,
/// humidity).
///
/// Extracting this once means every slider in the form shares identical
/// spacing/typography, and the value formatting logic (unit + decimal
/// places) lives in exactly one place.
///
/// Syllabus mapping: Layouts (Row/Column), MediaQuery-aware responsive text,
/// stateless widget composition.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.divisions,
    this.decimalPlaces = 1,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int? divisions;
  final int decimalPlaces;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                '${value.toStringAsFixed(decimalPlaces)}$unit',
                style: AppTheme.monoStyle(fontSize: 13, color: AppColors.primary),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.toStringAsFixed(decimalPlaces)}$unit',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
