import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/routes/route_arguments.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/core/constants/app_constants.dart';
import 'package:packwise_ai/core/utils/input_validators.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/providers/recommendation_provider.dart';
import 'package:packwise_ai/widgets/common/error_banner.dart';
import 'package:packwise_ai/widgets/common/primary_button.dart';
import 'package:packwise_ai/widgets/input/commodity_dropdown.dart';
import 'package:packwise_ai/widgets/input/labeled_slider.dart';

/// The commodity data-entry form: sliders for every continuous physical
/// property plus dropdowns for the two categorical properties, feeding a
/// [FoodCommodity] into [RecommendationProvider.requestRecommendation].
///
/// The form's max content width adapts to [MediaQuery] so it stays readable
/// (not stretched edge-to-edge) on tablets and desktop web while remaining
/// full-width on phones.
///
/// Syllabus mapping: Layouts, MediaQuery, Forms & validation, State
/// Management, Named Routing.
class InputFormView extends StatefulWidget {
  const InputFormView({super.key});

  @override
  State<InputFormView> createState() => _InputFormViewState();
}

class _InputFormViewState extends State<InputFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late FoodCommodity _commodity;

  @override
  void initState() {
    super.initState();
    _commodity = context.read<RecommendationProvider>().draftCommodity;
    _nameController = TextEditingController(text: _commodity.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(FoodCommodity Function(FoodCommodity current) updater) {
    setState(() => _commodity = updater(_commodity));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final FoodCommodity finalCommodity = _commodity.copyWith(name: _nameController.text.trim());
    final RecommendationProvider provider = context.read<RecommendationProvider>();
    await provider.requestRecommendation(finalCommodity);

    if (!mounted) return;
    if (provider.state == RecommendationViewState.success && provider.recommendation != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.result,
        arguments: ResultViewArguments(recommendation: provider.recommendation!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxContentWidth = screenWidth > 640 ? 560 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Commodity Details')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Commodity name',
                      hintText: 'e.g. Alphonso Mango',
                      prefixIcon: Icon(Icons.grass_rounded, color: AppColors.textSecondary),
                    ),
                    validator: InputValidators.commodityName,
                  ),
                  const SizedBox(height: 20),
                  CommodityDropdown<FoodCategory>(
                    label: 'Category',
                    value: _commodity.category,
                    items: FoodCategory.values,
                    labelBuilder: (FoodCategory c) => c.label,
                    onChanged: (FoodCategory? value) {
                      if (value != null) _update((FoodCommodity c) => c.copyWith(category: value));
                    },
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Physical & Chemical Properties',
                    children: <Widget>[
                      LabeledSlider(
                        label: 'Moisture Content',
                        value: _commodity.moisturePercent,
                        min: ValidationRangesRef.minMoisture,
                        max: ValidationRangesRef.maxMoisture,
                        unit: '%',
                        onChanged: (double v) =>
                            _update((FoodCommodity c) => c.copyWith(moisturePercent: v)),
                      ),
                      const SizedBox(height: 18),
                      LabeledSlider(
                        label: 'Fat Content',
                        value: _commodity.fatPercent,
                        min: ValidationRangesRef.minFat,
                        max: ValidationRangesRef.maxFat,
                        unit: '%',
                        onChanged: (double v) =>
                            _update((FoodCommodity c) => c.copyWith(fatPercent: v)),
                      ),
                      const SizedBox(height: 18),
                      LabeledSlider(
                        label: 'pH Level',
                        value: _commodity.ph,
                        min: ValidationRangesRef.minPh,
                        max: ValidationRangesRef.maxPh,
                        decimalPlaces: 1,
                        onChanged: (double v) => _update((FoodCommodity c) => c.copyWith(ph: v)),
                      ),
                      const SizedBox(height: 18),
                      LabeledSlider(
                        label: 'Respiration Rate',
                        value: _commodity.respirationRateMlCo2PerKgPerHr,
                        min: ValidationRangesRef.minRespiration,
                        max: 200,
                        unit: ' mL/kg/hr',
                        decimalPlaces: 0,
                        onChanged: (double v) => _update(
                            (FoodCommodity c) => c.copyWith(respirationRateMlCo2PerKgPerHr: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Storage & Shelf Life Requirements',
                    children: <Widget>[
                      LabeledSlider(
                        label: 'Desired Shelf Life',
                        value: _commodity.desiredShelfLifeDays.toDouble(),
                        min: 1,
                        max: 365,
                        unit: ' days',
                        decimalPlaces: 0,
                        onChanged: (double v) => _update(
                            (FoodCommodity c) => c.copyWith(desiredShelfLifeDays: v.round())),
                      ),
                      const SizedBox(height: 18),
                      LabeledSlider(
                        label: 'Storage Temperature',
                        value: _commodity.storageTemperatureCelsius,
                        min: ValidationRangesRef.minTemp,
                        max: ValidationRangesRef.maxTemp,
                        unit: '°C',
                        decimalPlaces: 0,
                        onChanged: (double v) => _update(
                            (FoodCommodity c) => c.copyWith(storageTemperatureCelsius: v)),
                      ),
                      const SizedBox(height: 18),
                      LabeledSlider(
                        label: 'Storage Humidity',
                        value: _commodity.storageHumidityPercent,
                        min: ValidationRangesRef.minHumidity,
                        max: ValidationRangesRef.maxHumidity,
                        unit: '%',
                        decimalPlaces: 0,
                        onChanged: (double v) => _update(
                            (FoodCommodity c) => c.copyWith(storageHumidityPercent: v)),
                      ),
                      const SizedBox(height: 18),
                      CommodityDropdown<StorageType>(
                        label: 'Storage Type',
                        value: _commodity.storageType,
                        items: StorageType.values,
                        labelBuilder: (StorageType s) => s.label,
                        onChanged: (StorageType? value) {
                          if (value != null) {
                            _update((FoodCommodity c) => c.copyWith(storageType: value));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Consumer<RecommendationProvider>(
                    builder: (BuildContext context, RecommendationProvider provider, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (provider.state == RecommendationViewState.error &&
                              provider.errorMessage != null) ...<Widget>[
                            ErrorBanner(message: provider.errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          PrimaryButton(
                            label: 'Get AI Recommendation',
                            icon: Icons.auto_awesome_rounded,
                            isLoading: provider.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Small local alias exposing [ValidationRanges] as slider-friendly doubles,
/// keeping the widget build method above readable.
abstract final class ValidationRangesRef {
  const ValidationRangesRef._();
  static const double minMoisture = ValidationRanges.minMoisturePercent;
  static const double maxMoisture = ValidationRanges.maxMoisturePercent;
  static const double minFat = ValidationRanges.minFatPercent;
  static const double maxFat = ValidationRanges.maxFatPercent;
  static const double minPh = ValidationRanges.minPh;
  static const double maxPh = ValidationRanges.maxPh;
  static const double minRespiration = ValidationRanges.minRespirationRate;
  static const double minTemp = ValidationRanges.minStorageTemperatureCelsius;
  static const double maxTemp = ValidationRanges.maxStorageTemperatureCelsius;
  static const double minHumidity = ValidationRanges.minStorageHumidityPercent;
  static const double maxHumidity = ValidationRanges.maxStorageHumidityPercent;
}
