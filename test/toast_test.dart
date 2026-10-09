import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/shared/widgets/app_toast.dart';

void main() {
  tearDown(() {
    AppToast.dismiss();
  });

  testWidgets('AppToast renders at the top of screen with message and title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppToast.showSuccess(
                    context,
                    'Reservation cancelled successfully',
                    title: 'Cancelled',
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to trigger top toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300)); // Complete slide in

    // Verify toast is rendered
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Reservation cancelled successfully'), findsOneWidget);

    // Verify top positioning
    final positionedFinder = find.byType(Positioned);
    expect(positionedFinder, findsWidgets);

    final positionedWidget = tester.widget<Positioned>(positionedFinder.first);
    expect(positionedWidget.top, isNotNull);
    expect(positionedWidget.top! >= 0, isTrue);
    expect(positionedWidget.bottom, isNull); // Ensures it is anchored to top, NOT bottom!

    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('AppToast showError renders correctly with error styling', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppToast.showError(
                    context,
                    'Failed to sign out',
                    title: 'Error',
                  );
                },
                child: const Text('Show Error Toast'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Failed to sign out'), findsOneWidget);

    final positionedFinder = find.byType(Positioned);
    final positionedWidget = tester.widget<Positioned>(positionedFinder.first);
    expect(positionedWidget.top, isNotNull);
    expect(positionedWidget.bottom, isNull);

    AppToast.dismiss();
    await tester.pumpAndSettle();
  });
}
