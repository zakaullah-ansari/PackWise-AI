import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/widgets/common/primary_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('PrimaryButton invokes onPressed when tapped', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Get AI Recommendation', onPressed: () => tapCount++)),
    );

    expect(find.text('Get AI Recommendation'), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('PrimaryButton shows a spinner and ignores taps while isLoading', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Submit', isLoading: true, onPressed: () => tapCount++)),
    );

    // The label is swapped out for a CircularProgressIndicator while loading.
    expect(find.text('Submit'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('PrimaryButton ignores taps when onPressed is null', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const PrimaryButton(label: 'Disabled', onPressed: null)));

    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pump();

    // No exception should be thrown; nothing to assert beyond successful pump.
    expect(find.text('Disabled'), findsOneWidget);
  });
}
