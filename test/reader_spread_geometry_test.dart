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

  test(
    'mixed portrait and landscape pages share a height and fill the width',
    () {
      const viewport = Size(1000, 600);
      final rects = readerRowRects(viewport, [
        const Size(300, 600),
        const Size(900, 600),
      ]);
      expect(rects[0].height, closeTo(rects[1].height, 1e-8));
      expect(rects[0].right, closeTo(rects[1].left, 1e-8));
      expect(rects[0].width, closeTo(250, 1e-8));
      expect(rects[1].width, closeTo(750, 1e-8));
      final union = rects[0].expandToInclude(rects[1]);
      expect(union.width, closeTo(viewport.width, 1e-8));
      expect(union.height, closeTo(500, 1e-8));
      expect(union.center.dy, closeTo(viewport.height / 2, 1e-8));
    },
  );

  test('vertical rows share a width and fill the height', () {
    const viewport = Size(600, 1000);
    final rects = readerRowRects(viewport, [
      const Size(600, 300),
      const Size(600, 900),
    ], axis: Axis.vertical);
    expect(rects[0].width, closeTo(rects[1].width, 1e-8));
    expect(rects[0].bottom, closeTo(rects[1].top, 1e-8));
    expect(rects[0].width / rects[0].height, closeTo(2, 1e-8));
    expect(rects[1].width / rects[1].height, closeTo(2 / 3, 1e-8));
    final union = rects[0].expandToInclude(rects[1]);
    // Height-bound: the column is 500 wide and 1000 tall, centered.
    expect(union.height, closeTo(viewport.height, 1e-8));
    expect(union.width, closeTo(500, 1e-8));
    expect(union.center.dx, closeTo(viewport.width / 2, 1e-8));
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
            if (axis == Axis.horizontal) {
              expect(rects[0].height, closeTo(rects[1].height, 1e-8));
            } else {
              expect(rects[0].width, closeTo(rects[1].width, 1e-8));
            }
            // The largest possible group always saturates one axis.
            final fillsWidth = (union.width - viewport.width).abs() < 1e-6;
            final fillsHeight = (union.height - viewport.height).abs() < 1e-6;
            expect(
              fillsWidth || fillsHeight,
              isTrue,
              reason: 'row must fill the width or the height',
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
