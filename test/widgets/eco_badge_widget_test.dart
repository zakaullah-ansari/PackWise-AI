import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/mixins/sustainability_score_mixin.dart';
import 'package:packwise_ai/widgets/result/eco_badge.dart';

/// First `testWidgets`/`pumpWidget` example in this project — all other
/// tests exercise pure-Dart logic. Widget tests pump a real widget tree into
/// an offscreen test binding and assert on the rendered output via `find`.
///
/// Syllabus mapping: Flutter Widget Testing.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('EcoBadge renders the grade label and rounded score', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const EcoBadge(score: 87.4, grade: EcoGrade.a)));

    expect(find.text('A · 87'), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
  });

  testWidgets('EcoBadge shows A+ for a top score', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const EcoBadge(score: 95, grade: EcoGrade.aPlus)));

    expect(find.text('A+ · 95'), findsOneWidget);
  });
}
