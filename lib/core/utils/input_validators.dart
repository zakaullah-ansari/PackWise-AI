import 'package:packwise_ai/core/constants/app_constants.dart';

/// Static form-field validators for the commodity input form.
///
/// Every method matches the `String? Function(String?)` signature expected
/// by [TextFormField.validator], so widgets can wire them up directly:
/// `validator: InputValidators.moisturePercent`.
///
/// Keeping validators as pure functions (no widget/BuildContext dependency)
/// makes them trivially unit-testable.
///
/// Syllabus mapping: Static methods, string parsing, Exception-free
/// defensive programming, Form validation, Layouts (used inside
/// [TextFormField]s on [InputFormView]).
abstract final class InputValidators {
  const InputValidators._();

  /// Generic required-field check reused by every specific validator below.
  static String? _requiredNumber(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldLabel must be a valid number';
    }
    return null;
  }

  /// Validates a value lies within an inclusive [min]/[max] numeric range,
  /// returning a descriptive error otherwise.
  static String? _inRange(
    String? value,
    String fieldLabel,
    double min,
    double max, {
    String unit = '',
  }) {
    final String? requiredError = _requiredNumber(value, fieldLabel);
    if (requiredError != null) return requiredError;

    final double parsed = double.parse(value!.trim());
    if (parsed < min || parsed > max) {
      return '$fieldLabel must be between $min and $max$unit';
    }
    return null;
  }

  static String? commodityName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Commodity name is required';
    }
    if (value.trim().length < 2) {
      return 'Commodity name must be at least 2 characters';
    }
    return null;
  }

  static String? moisturePercent(String? value) => _inRange(
        value,
        'Moisture',
        ValidationRanges.minMoisturePercent,
        ValidationRanges.maxMoisturePercent,
        unit: '%',
      );

  static String? fatPercent(String? value) => _inRange(
        value,
        'Fat content',
        ValidationRanges.minFatPercent,
        ValidationRanges.maxFatPercent,
        unit: '%',
      );

  static String? ph(String? value) => _inRange(
        value,
        'pH',
        ValidationRanges.minPh,
        ValidationRanges.maxPh,
      );

  static String? respirationRate(String? value) => _inRange(
        value,
        'Respiration rate',
        ValidationRanges.minRespirationRate,
        ValidationRanges.maxRespirationRate,
        unit: ' mL CO2/kg/hr',
      );

  static String? shelfLifeDays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Desired shelf life is required';
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Shelf life must be a whole number of days';
    }
    if (parsed < ValidationRanges.minShelfLifeDays ||
        parsed > ValidationRanges.maxShelfLifeDays) {
      return 'Shelf life must be between ${ValidationRanges.minShelfLifeDays} '
          'and ${ValidationRanges.maxShelfLifeDays} days';
    }
    return null;
  }

  static String? storageTemperature(String? value) => _inRange(
        value,
        'Storage temperature',
        ValidationRanges.minStorageTemperatureCelsius,
        ValidationRanges.maxStorageTemperatureCelsius,
        unit: '°C',
      );

  static String? storageHumidity(String? value) => _inRange(
        value,
        'Storage humidity',
        ValidationRanges.minStorageHumidityPercent,
        ValidationRanges.maxStorageHumidityPercent,
        unit: '%',
      );

  /// Email validator used by the auth screens.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final RegExp emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Password validator used by the auth screens.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
