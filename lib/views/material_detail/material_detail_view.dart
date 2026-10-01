import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/data/models/layer_spec.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/painters/barrier_chart_painter.dart';
import 'package:packwise_ai/painters/packaging_layer_painter.dart';
import 'package:packwise_ai/widgets/result/eco_badge.dart';
import 'package:packwise_ai/widgets/result/map_gas_chip.dart';

/// Full specification deep-dive for a single [RecommendedMaterialResult]:
/// layered film cross-section, OTR/WVTR bar chart, MAP gas mix, and a
/// shareable QR code summarizing the recommendation.
///
/// Syllabus mapping: CustomPainter (layer + bar chart), third-party widget
/// integration (`qr_flutter`), Layouts, OOP (consuming the abstract
/// [PackagingMaterial] polymorphically).
class MaterialDetailView extends StatelessWidget {
  const MaterialDetailView({
    super.key,
    required this.materialResult,
    required this.recommendation,
  });

  final RecommendedMaterialResult materialResult;
  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final PackagingMaterial material = materialResult.material;
    final List<LayerSpec> layers = LayerSpec.forMaterial(
      material,
      totalThicknessMicrons: materialResult.recommendedThicknessMicrons,
    );
    final String qrPayload = _buildQrPayload(material);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(material.displayName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    material.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(width: 12),
                EcoBadge(score: materialResult.sustainabilityScore, grade: materialResult.ecoGrade),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Film Cross-Section'),
            const SizedBox(height: 10),
            Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.glassBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                size: const Size(double.infinity, 90),
                painter: PackagingLayerPainter(layers: layers),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: <Widget>[
                for (final LayerSpec layer in layers)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: layer.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(layer.label,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _sectionTitle('Barrier Performance (log scale)'),
            const SizedBox(height: 10),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: BarrierChartPainter(
                  entries: <BarrierChartEntry>[
                    BarrierChartEntry(
                      label: 'OTR vs WVTR',
                      otrCm3M2Day: materialResult.predictedOtrCm3M2Day,
                      wvtrGM2Day: materialResult.predictedWvtrGM2Day,
                    ),
                  ],
                ),
              ),
            ),
            _legendRow(),
            const SizedBox(height: 28),
            _sectionTitle('Modified Atmosphere Packaging (MAP) Gas Mix'),
            const SizedBox(height: 10),
            MapGasChip(gasRatioPercent: materialResult.mapGasRatioPercent),
            const SizedBox(height: 28),
            _sectionTitle('Full Specification'),
            const SizedBox(height: 10),
            _specTable(materialResult, material),
            const SizedBox(height: 28),
            _sectionTitle('AI Rationale'),
            const SizedBox(height: 10),
            Text(
              materialResult.aiRationale,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Share Specification'),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  Widget _legendRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          _legendDot(AppColors.primary, 'OTR (cm³/m²/day)'),
          const SizedBox(width: 16),
          _legendDot(AppColors.secondary, 'WVTR (g/m²/day)'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
      ],
    );
  }

  Widget _specTable(RecommendedMaterialResult result, PackagingMaterial material) {
    final List<MapEntry<String, String>> rows = <MapEntry<String, String>>[
      MapEntry<String, String>('Recommended Thickness', '${result.recommendedThicknessMicrons.toStringAsFixed(0)} µm'),
      MapEntry<String, String>('Predicted OTR', '${result.predictedOtrCm3M2Day.toStringAsFixed(2)} cm³/m²/day'),
      MapEntry<String, String>('Predicted WVTR', '${result.predictedWvtrGM2Day.toStringAsFixed(2)} g/m²/day'),
      MapEntry<String, String>('Barrier Rating', result.barrierRating.label),
      MapEntry<String, String>('Predicted Shelf Life', '${result.predictedShelfLifeDays} days'),
      MapEntry<String, String>('AI Confidence', '${(result.confidenceScore * 100).toStringAsFixed(0)}%'),
      MapEntry<String, String>('Recyclable', material.isRecyclable ? 'Yes' : 'No'),
      MapEntry<String, String>('Biodegradable', material.isBiodegradable ? 'Yes' : 'No'),
      MapEntry<String, String>('Relative Cost Index', '${material.costIndex} / 5'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(rows[i].key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  Text(rows[i].value, style: AppTheme.monoStyle(fontSize: 12.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildQrPayload(PackagingMaterial material) {
    return 'PackWise AI Recommendation\n'
        'Material: ${material.displayName}\n'
        'Thickness: ${materialResult.recommendedThicknessMicrons.toStringAsFixed(0)}µm\n'
        'OTR: ${materialResult.predictedOtrCm3M2Day.toStringAsFixed(2)} cm3/m2/day\n'
        'WVTR: ${materialResult.predictedWvtrGM2Day.toStringAsFixed(2)} g/m2/day\n'
        'Predicted Shelf Life: ${materialResult.predictedShelfLifeDays} days\n'
        'For: ${recommendation.commodity.name}';
  }
}
