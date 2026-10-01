import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';

/// A generic, glass-styled dropdown for any enum type [T], used for both
/// [FoodCategory] and [StorageType] selection on [InputFormView].
///
/// Using a generic (`<T extends Enum>`) instead of duplicating near-identical
/// dropdown widgets for each enum demonstrates Dart generics while keeping
/// the form screen's build method declarative and short.
///
/// Syllabus mapping: Generics, Enums, Layouts, Dropdown form fields.
class CommodityDropdown<T extends Enum> extends StatelessWidget {
  const CommodityDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
          items: <DropdownMenuItem<T>>[
            for (final T item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
          ],
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ],
    );
  }
}
