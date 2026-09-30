import 'package:flutter/painting.dart' show Color;
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';

/// Describes a single physical layer inside a (possibly multi-layer)
/// packaging film cross-section, consumed by [PackagingLayerPainter].
///
/// Real-world food packaging is very rarely a single homogeneous polymer —
/// even "simple" films are often co-extruded. Modeling layers explicitly
/// lets the UI teach that nuance visually instead of just naming a material.
///
/// Syllabus mapping: OOP (simple immutable data class), CustomPainter data
/// modeling, factory constructors encoding domain knowledge.
class LayerSpec {
  const LayerSpec({
    required this.label,
    required this.thicknessMicrons,
    required this.color,
  });

  final String label;
  final double thicknessMicrons;
  final Color color;

  /// Builds the realistic multi-layer stack-up for a given [material],
  /// thickest-relevant-layer proportions approximated for illustrative
  /// purposes (this is a teaching visualization, not a manufacturing spec).
  static List<LayerSpec> forMaterial(
    PackagingMaterial material, {
    required double totalThicknessMicrons,
  }) {
    switch (material.type) {
      case MaterialType.aluminumFoil:
        return <LayerSpec>[
          LayerSpec(
            label: 'PET Outer Layer',
            thicknessMicrons: totalThicknessMicrons * 0.25,
            color: AppColors.primary.withOpacity(0.55),
          ),
          LayerSpec(
            label: 'Adhesive Bond',
            thicknessMicrons: totalThicknessMicrons * 0.08,
            color: AppColors.textSecondary.withOpacity(0.35),
          ),
          LayerSpec(
            label: 'Aluminum Foil Core',
            thicknessMicrons: totalThicknessMicrons * 0.42,
            color: const Color(0xFFC7CDD6),
          ),
          LayerSpec(
            label: 'LDPE Sealant Layer',
            thicknessMicrons: totalThicknessMicrons * 0.25,
            color: AppColors.secondary.withOpacity(0.55),
          ),
        ];

      case MaterialType.metalizedFilm:
        return <LayerSpec>[
          LayerSpec(
            label: 'Base Polymer Film',
            thicknessMicrons: totalThicknessMicrons * 0.55,
            color: AppColors.primary.withOpacity(0.5),
          ),
          LayerSpec(
            label: 'Vapor-Deposited Aluminum',
            thicknessMicrons: totalThicknessMicrons * 0.05,
            color: const Color(0xFFC7CDD6),
          ),
          LayerSpec(
            label: 'Sealant Layer',
            thicknessMicrons: totalThicknessMicrons * 0.40,
            color: AppColors.secondary.withOpacity(0.5),
          ),
        ];

      case MaterialType.microPerforated:
        return <LayerSpec>[
          LayerSpec(
            label: 'Perforated Base Film',
            thicknessMicrons: totalThicknessMicrons * 0.85,
            color: AppColors.primary.withOpacity(0.45),
          ),
          LayerSpec(
            label: 'Sealant Layer',
            thicknessMicrons: totalThicknessMicrons * 0.15,
            color: AppColors.secondary.withOpacity(0.45),
          ),
        ];

      case MaterialType.ldpe:
      case MaterialType.hdpe:
      case MaterialType.pet:
      case MaterialType.pla:
      case MaterialType.biodegradable:
        return <LayerSpec>[
          LayerSpec(
            label: material.displayName,
            thicknessMicrons: totalThicknessMicrons,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ];
    }
  }
}
