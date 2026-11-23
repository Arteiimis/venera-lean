import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/reader_fixture.dart' as fixture;

void main() {
  testWidgets(
    'a portrait page takes the height while a landscape page fills the width',
    (tester) async {
      await fixture.openReader(
        tester,
        'galleryLeftToRight',
        imageSizes: {9: const Size(300, 600), 10: const Size(900, 600)},
        settings: {'readerScreenPicNumberForLandscape': 2},
      );
      await fixture.settle(tester);

      final portrait = tester.getRect(
        find.byKey(const ValueKey('reader-spread-image-9')),
      );
      final landscape = tester.getRect(
        find.byKey(const ValueKey('reader-spread-image-10')),
      );
      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      final union = portrait.expandToInclude(landscape);

      // The portrait page uses the full height of the image area and the
      // landscape page takes the remaining width, so the pair fills it.
      expect(portrait.height, closeTo(union.height, 0.5));
      expect(portrait.top, closeTo(union.top, 0.5));
      expect(landscape.width, closeTo(union.width - portrait.width, 0.5));
      expect(landscape.left, closeTo(portrait.right, 0.5));
      expect(portrait.width / portrait.height, closeTo(0.5, 0.01));
      expect(landscape.width / landscape.height, closeTo(1.5, 0.01));
      // The row covers the visible area instead of leaving a letterboxed slot.
      expect(union.width, greaterThan(viewport.width * 0.9));
      expect(union.height, greaterThan(viewport.height * 0.9));
      expect(union.left, greaterThanOrEqualTo(-0.5));
      expect(union.top, greaterThanOrEqualTo(-0.5));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      await fixture.settle(tester);
    },
  );

  testWidgets('the next page is already laid out when it appears', (
    tester,
  ) async {
    final dynamic state = await fixture.openReader(
      tester,
      'galleryLeftToRight',
      imageSizes: {
        9: const Size(300, 600),
        10: const Size(900, 600),
        11: const Size(900, 600),
        12: const Size(300, 600),
      },
      settings: {'readerScreenPicNumberForLandscape': 2},
    );
    await fixture.settle(tester);

    // The aspect ratios of the neighbouring page are resolved while it is
    // still off screen, so turning the page never shows a provisional layout.
    expect(state.spreadImageSizes.containsKey(10), isTrue);
    expect(state.spreadImageSizes.containsKey(11), isTrue);

    state.turnPage(forward: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final landscape = tester.getRect(
      find.byKey(const ValueKey('reader-spread-image-11')),
    );
    final portrait = tester.getRect(
      find.byKey(const ValueKey('reader-spread-image-12')),
    );
    final union = landscape.expandToInclude(portrait);
    expect(landscape.width, closeTo(union.width - portrait.width, 0.5));
    expect(landscape.width / landscape.height, closeTo(1.5, 0.01));
    expect(portrait.width / portrait.height, closeTo(0.5, 0.01));
    expect(portrait.height, closeTo(union.height, 0.5));
    // The two pages are not letterboxed inside equal slots.
    expect((landscape.width - portrait.width).abs(), greaterThan(100));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await fixture.settle(tester);
  });
}
