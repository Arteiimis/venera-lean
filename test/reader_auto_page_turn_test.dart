import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/reader_fixture.dart' as fixture;

void main() {
  testWidgets('space toggles auto page turning and shows its state', (
    tester,
  ) async {
    final dynamic state = await fixture.openReader(
      tester,
      'galleryLeftToRight',
    );
    const indicator = ValueKey('auto-page-turn-indicator');
    double opacity() =>
        tester.widget<AnimatedOpacity>(find.byKey(indicator)).opacity;

    expect(state.autoPageTurningTimer, isNull);
    expect(opacity(), 0);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(state.autoPageTurningTimer, isNotNull);
    expect(opacity(), 1);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(state.autoPageTurningTimer, isNull);
    expect(opacity(), 1);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // The icon fades out by itself; the toolbar keeps the current state.
    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 0);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await fixture.settle(tester);
  });
}
