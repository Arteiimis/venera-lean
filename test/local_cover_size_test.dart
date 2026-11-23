import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/image_provider/local_comic_image.dart';
import 'package:venera/foundation/local.dart';

/// Runs [provider] through the real pipeline with a decoder that records the
/// requested target size and then decodes the tiny cover itself.
Future<ui.TargetImageSizeCallback?> _requestedTargetSize(
  LocalComicImageProvider provider,
) async {
  ui.TargetImageSizeCallback? requested;
  final completer = provider.loadImage(provider, (
    buffer, {
    getTargetSize,
  }) async {
    requested = getTargetSize;
    return ui.instantiateImageCodecWithSize(buffer);
  });
  final loaded = Completer<void>();
  completer.addListener(
    ImageStreamListener(
      (_, _) => loaded.complete(),
      onError: (Object error, StackTrace? stack) =>
          loaded.completeError(error, stack),
    ),
  );
  await loaded.future;
  return requested;
}

Future<Uint8List> _cover() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 8),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 8);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local covers request a decode within the cover pixel budget', () async {
    final root = await Directory.systemTemp.createTemp('venera-cover-size-');
    addTearDown(() => root.delete(recursive: true));
    File('${root.path}/cover.png').writeAsBytesSync(await _cover());
    final comic = LocalComic(
      id: '1',
      title: 'Cover',
      subtitle: '',
      tags: [],
      directory: root.path,
      chapters: null,
      cover: 'cover.png',
      comicType: ComicType.local,
      downloadedChapters: [],
      createdAt: DateTime(2026),
    );
    final provider = LocalComicImageProvider(comic);
    expect(provider.enableResize, isTrue);

    final requested = await _requestedTargetSize(provider);
    expect(requested, isNotNull);
    final huge = requested!(2400, 3400);
    expect(huge.width! * huge.height!, lessThanOrEqualTo(800 * 1200));
    expect(huge.width! / huge.height!, closeTo(2400 / 3400, 0.01));
    final small = requested(100, 150);
    expect((small.width, small.height), (100, 150));
  });
}
