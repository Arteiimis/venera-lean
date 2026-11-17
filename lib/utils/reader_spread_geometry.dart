import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Axis;

/// Wide artwork benefits from the full viewport regardless of its semantics.
bool isWideReaderImage(Size size) =>
    size.width.isFinite &&
    size.height.isFinite &&
    size.height > 0 &&
    size.width / size.height >= 1.2;

/// A spread has one page height. Images retain their own aspect ratios.
/// Null slots reserve a matching paper-sized blank for the cover or last page.
List<Rect> readerSpreadRects(Size viewport, List<Size?> pages) =>
    readerRowRects(viewport, pages);

/// Lays out several images that share one row (or column) so the group is as
/// large as the viewport allows without cropping or overlapping.
///
/// Every image keeps its aspect ratio and shares one height (horizontal rows)
/// or one width (vertical rows). The shared size is the largest that keeps the
/// whole group inside the viewport, so the group always fills either the full
/// width or the full height and the leftover space stays symmetric.
List<Rect> readerRowRects(
  Size viewport,
  List<Size?> pages, {
  Axis axis = Axis.horizontal,
}) {
  if (pages.isEmpty ||
      viewport.isEmpty ||
      !viewport.width.isFinite ||
      !viewport.height.isFinite) {
    return [];
  }
  final ratios = _aspectRatios(pages);
  final rects = <Rect>[];
  if (axis == Axis.horizontal) {
    final totalRatio = ratios.fold<double>(0, (sum, ratio) => sum + ratio);
    final height = math.min(viewport.height, viewport.width / totalRatio);
    final top = (viewport.height - height) / 2;
    var left = (viewport.width - totalRatio * height) / 2;
    for (final ratio in ratios) {
      final rect = Rect.fromLTWH(left, top, height * ratio, height);
      left = rect.right;
      rects.add(rect);
    }
  } else {
    final totalInverse = ratios.fold<double>(
      0,
      (sum, ratio) => sum + 1 / ratio,
    );
    final width = math.min(viewport.width, viewport.height / totalInverse);
    final left = (viewport.width - width) / 2;
    var top = (viewport.height - totalInverse * width) / 2;
    for (final ratio in ratios) {
      final rect = Rect.fromLTWH(left, top, width, width / ratio);
      top = rect.bottom;
      rects.add(rect);
    }
  }
  return rects;
}

List<double> _aspectRatios(List<Size?> pages) {
  bool valid(Size? size) =>
      size != null &&
      size.width > 0 &&
      size.height > 0 &&
      size.width.isFinite &&
      size.height.isFinite;

  final known = pages.where(valid).cast<Size>().toList();
  final fallback = known.isEmpty ? const Size(2, 3) : known.first;
  return [
    for (final size in pages)
      valid(size)
          ? size!.width / size.height
          : fallback.width / fallback.height,
  ];
}
