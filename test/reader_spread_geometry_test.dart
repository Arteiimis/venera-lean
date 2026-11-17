import 'dart:ui';

import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/utils/reader_spread_geometry.dart';

void main() {
  test(
    'unequal pages share height, preserve proportions and meet at the seam',
    () {
      for (final viewport in [const Size(1000, 600), const Size(600, 1000)]) {
        final rects = readerSpreadRects(viewport, [
          const Size(300, 600),
          const Size(510, 600),
        ]);
        expect(rects[0].height, closeTo(rects[1].height, 1e-8));
        expect(rects[0].top, rects[1].top);
        expect(rects[0].right, closeTo(rects[1].left, 1e-8));
        expect(rects[0].width / rects[0].height, closeTo(.5, 1e-8));
        expect(rects[1].width / rects[1].height, closeTo(.85, 1e-8));
        for (final rect in rects) {
          expect(rect.left, greaterThanOrEqualTo(-1e-8));
          expect(rect.right, lessThanOrEqualTo(viewport.width + 1e-8));
          expect(rect.height, lessThanOrEqualTo(viewport.height));
        }
      }
    },
  );

  test(
    'cover blanks match the actual page and wide artwork uses both slots',
    () {
      const viewport = Size(1000, 600);
      final cover = readerSpreadRects(viewport, [null, const Size(400, 600)]);
      expect(cover[0].size, cover[1].size);
      final wide = readerSpreadRects(viewport, [const Size(1200, 600)]).single;
      expect(wide.width, 1000);
      expect(wide.height, 500);
    },
  );

  test('unknown and invalid sizes have finite placeholders', () {
    for (final size in [null, Size.zero, const Size(double.infinity, 600)]) {
      final rects = readerSpreadRects(const Size(1000, 600), [size, null]);
      expect(rects, hasLength(2));
      expect(rects.every((rect) => rect.isFinite && !rect.isEmpty), isTrue);
    }
    expect(readerSpreadRects(Size.zero, [null]), isEmpty);
  });

  test('a portrait page takes the height and a landscape page the width', () {
    const viewport = Size(1000, 600);
    final rects = readerRowRects(viewport, [
      const Size(300, 600),
      const Size(900, 600),
    ]);
    // The portrait page is height-bound at 300x600; the landscape page takes
    // the remaining 700px of width and is 466.67 tall instead of 500.
    expect(rects[0].width, closeTo(300, 1e-8));
    expect(rects[0].height, closeTo(600, 1e-8));
    expect(rects[1].width, closeTo(700, 1e-8));
    expect(rects[1].height, closeTo(700 / 1.5, 1e-8));
    expect(rects[0].right, closeTo(rects[1].left, 1e-8));
    expect(rects[0].width / rects[0].height, closeTo(0.5, 1e-8));
    expect(rects[1].width / rects[1].height, closeTo(1.5, 1e-8));
    final union = rects[0].expandToInclude(rects[1]);
    expect(union.width, closeTo(viewport.width, 1e-8));
    expect(union.height, closeTo(viewport.height, 1e-8));
  });

  test('equal aspect ratios still fall back to a shared size', () {
    const viewport = Size(1000, 600);
    final rects = readerRowRects(viewport, [
      const Size(400, 600),
      const Size(400, 600),
    ]);
    // Both pages already fit at full height, so they keep a shared height and
    // the row stays narrower than the viewport instead of being enlarged.
    expect(rects[0].height, closeTo(rects[1].height, 1e-8));
    expect(rects[0].top, closeTo(rects[1].top, 1e-8));
    expect(rects[0].height, closeTo(viewport.height, 1e-8));
    expect(rects[0].width + rects[1].width, closeTo(800, 1e-8));
    expect(rects.first.left, closeTo(100, 1e-8));
  });

  test('vertical rows balance widths and fill the height', () {
    const viewport = Size(600, 1000);
    final rects = readerRowRects(viewport, [
      const Size(600, 300),
      const Size(600, 900),
    ], axis: Axis.vertical);
    // The wide image is width-bound at 600x300; the tall one takes the rest.
    expect(rects[0].width, closeTo(600, 1e-8));
    expect(rects[0].height, closeTo(300, 1e-8));
    expect(rects[1].width, closeTo(700 * 2 / 3, 1e-8));
    expect(rects[1].height, closeTo(700, 1e-8));
    expect(rects[0].width / rects[0].height, closeTo(2, 1e-8));
    expect(rects[1].width / rects[1].height, closeTo(2 / 3, 1e-8));
    expect(rects[0].bottom, closeTo(rects[1].top, 1e-8));
    final union = rects[0].expandToInclude(rects[1]);
    expect(union.width, closeTo(viewport.width, 1e-8));
    expect(union.height, closeTo(viewport.height, 1e-8));
  });

  test('any row stays inside the viewport and saturates one axis', () {
    const viewports = [Size(1000, 600), Size(600, 1000), Size(800, 800)];
    const ratios = [0.4, 0.5, 0.8, 1.0, 1.4, 2.2];
    for (final viewport in viewports) {
      for (var i = 0; i < ratios.length; i++) {
        for (var j = 0; j < ratios.length; j++) {
          final sizes = [
            Size(ratios[i] * 100, 100),
            Size(ratios[j] * 100, 100),
          ];
          for (final axis in Axis.values) {
            final rects = readerRowRects(viewport, sizes, axis: axis);
            expect(rects, hasLength(2));
            final union = rects[0].expandToInclude(rects[1]);
            expect(union.width, lessThanOrEqualTo(viewport.width + 1e-8));
            expect(union.height, lessThanOrEqualTo(viewport.height + 1e-8));
            // Aspect ratios are preserved.
            expect(rects[0].width / rects[0].height, closeTo(ratios[i], 1e-6));
            expect(rects[1].width / rects[1].height, closeTo(ratios[j], 1e-6));
            // The group fills the main axis, unless every image already uses
            // the full cross size.
            final fillsMain = axis == Axis.horizontal
                ? (union.width - viewport.width).abs() < 1e-6
                : (union.height - viewport.height).abs() < 1e-6;
            final allFullCross = axis == Axis.horizontal
                ? rects.every((r) => (r.height - viewport.height).abs() < 1e-6)
                : rects.every((r) => (r.width - viewport.width).abs() < 1e-6);
            expect(
              fillsMain || allFullCross,
              isTrue,
              reason: 'row must fill the main axis or use the full cross size',
            );
            for (final rect in rects) {
              expect(rect.left, greaterThanOrEqualTo(-1e-8));
              expect(rect.top, greaterThanOrEqualTo(-1e-8));
              expect(rect.right, lessThanOrEqualTo(viewport.width + 1e-8));
              expect(rect.bottom, lessThanOrEqualTo(viewport.height + 1e-8));
            }
          }
        }
      }
    }
  });

  test('width detection is conservative and rejects invalid metadata', () {
    expect(isWideReaderImage(const Size(2000, 1500)), isTrue);
    expect(isWideReaderImage(const Size(1000, 1500)), isFalse);
    expect(isWideReaderImage(const Size(1000, 1000)), isFalse);
    expect(isWideReaderImage(Size.zero), isFalse);
  });
}
