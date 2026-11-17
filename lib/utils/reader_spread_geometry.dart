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
List<Rect> readerSpreadRects(Size viewport, List<Size?> pages) {
  if (pages.isEmpty ||
      viewport.isEmpty ||
      !viewport.width.isFinite ||
      !viewport.height.isFinite) {
    return [];
  }
  final ratios = _aspectRatios(pages);
  final totalRatio = ratios.fold<double>(0, (sum, ratio) => sum + ratio);
  final height = math.min(viewport.height, viewport.width / totalRatio);
  final top = (viewport.height - height) / 2;
  var left = (viewport.width - totalRatio * height) / 2;
  final result = <Rect>[];
  for (final ratio in ratios) {
    final rect = Rect.fromLTWH(left, top, height * ratio, height);
    left = rect.right;
    result.add(rect);
  }
  return result;
}

/// Lays out the images of one screen so each of them is as large as possible.
///
/// Unlike a book spread, heights may differ: the smallest displayed area is
/// maximised and every image keeps its own aspect ratio, so a portrait page can
/// take the full height while a wide neighbour takes the rest of the width.
/// The group always fills the main axis (the width for horizontal rows) with no
/// overlap, and an image never exceeds the viewport, so nothing is cropped.
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
  final horizontal = axis == Axis.horizontal;
  final cross = horizontal ? viewport.height : viewport.width;
  final main = horizontal ? viewport.width : viewport.height;
  final aspects = _aspectRatios(pages);
  // Cross size per unit of main size for each image.
  final ratios = [
    for (final aspect in aspects) horizontal ? aspect : 1 / aspect,
  ];
  final sizes = _balancedCrossSizes(ratios, cross, main);
  final totalMain = sumMainExtents(ratios, sizes);
  var offset = (main - totalMain) / 2;
  final rects = <Rect>[];
  for (var i = 0; i < sizes.length; i++) {
    final crossSize = sizes[i];
    final mainSize = crossSize * ratios[i];
    final crossOffset = (cross - crossSize) / 2;
    rects.add(
      horizontal
          ? Rect.fromLTWH(offset, crossOffset, mainSize, crossSize)
          : Rect.fromLTWH(crossOffset, offset, crossSize, mainSize),
    );
    offset += mainSize;
  }
  return rects;
}

/// Total extent of a row along its main axis.
double sumMainExtents(List<double> ratios, List<double> crossSizes) {
  var total = 0.0;
  for (var i = 0; i < ratios.length; i++) {
    total += ratios[i] * crossSizes[i];
  }
  return total;
}

/// Maximises the smallest displayed area of the group.
///
/// Equal areas give `crossSize_i = sqrt(area / ratio_i)`, capped by the viewport
/// cross size. The area is bisected until the row exactly fills the main axis,
/// or every image already sits at the full cross size.
List<double> _balancedCrossSizes(
  List<double> ratios,
  double cross,
  double main,
) {
  final full = [for (var i = 0; i < ratios.length; i++) cross];
  if (sumMainExtents(ratios, full) <= main) {
    return full;
  }
  var low = 0.0;
  var high = ratios.fold<double>(0, (max, ratio) => math.max(max, ratio));
  high = high * cross * cross;
  for (var i = 0; i < 60; i++) {
    final area = (low + high) / 2;
    final sizes = [
      for (final ratio in ratios) math.min(cross, math.sqrt(area / ratio)),
    ];
    if (sumMainExtents(ratios, sizes) > main) {
      high = area;
    } else {
      low = area;
    }
  }
  return [for (final ratio in ratios) math.min(cross, math.sqrt(low / ratio))];
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
