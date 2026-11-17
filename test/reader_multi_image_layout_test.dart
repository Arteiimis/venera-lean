import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/reader_fixture.dart' as fixture;

void main() {
  testWidgets(
    'a portrait and a landscape page share one height and fill the width',
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

      // Equal height, seam in the middle, aspect ratios preserved.
      expect(portrait.height, closeTo(landscape.height, 0.5));
      expect(portrait.top, closeTo(landscape.top, 0.5));
      expect(portrait.right, closeTo(landscape.left, 0.5));
      expect(portrait.width / portrait.height, closeTo(0.5, 0.01));
      expect(landscape.width / landscape.height, closeTo(1.5, 0.01));

      // The pair fills the width without overflowing the viewport.
      expect(union.width, closeTo(viewport.width, 0.5));
      expect(union.height, lessThanOrEqualTo(viewport.height + 0.5));
      expect(union.left, greaterThanOrEqualTo(-0.5));
      expect(union.top, greaterThanOrEqualTo(-0.5));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      await fixture.settle(tester);
    },
  );
}
