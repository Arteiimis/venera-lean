import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/components/window_frame.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/foundation/history.dart';
import 'package:venera/foundation/local.dart';
import 'package:venera/pages/reader/reader.dart';

import 'test_translations.dart';

/// Pumps frames while real filesystem work runs, so reader fixtures settle
/// deterministically without depending on wall-clock timers.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens a local 30-page reader in [mode] with a temporary data directory.
Future<dynamic> openReader(
  WidgetTester tester,
  String mode, {
  Map<int, Size> imageSizes = const {},
}) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ensureTestTranslations();
  final root = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('reader-fixture-'),
  ))!;
  App.dataPath = root.path;
  App.cachePath = root.path;
  for (final channel in [
    'flutter_memory_info',
    'window_manager',
    'venera/method_channel',
  ]) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      MethodChannel(channel),
      (call) async => call.method == 'isMaximized' ? false : null,
    );
  }
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => root.path,
  );
  final values = <String, dynamic>{
    'readerMode': mode,
    'readerTwoPageSpread': false,
    'readerSpreadOverrides': <String, dynamic>{},
    'showSingleImageOnFirstPage': false,
    'readerScreenPicNumberForLandscape': 1,
    'readerScreenPicNumberForPortrait': 1,
    'enablePageAnimation': false,
    'limitImageWidth': true,
    'enableClockAndBatteryInfoInReader': false,
    'enableTurnPageByVolumeKey': false,
    'removeReadLaterOnComplete': false,
    'enableLongPressToZoom': true,
    'comicSpecificSettings': <String, dynamic>{},
    'deviceSpecificSettings': <String, dynamic>{},
    'deviceId': 'reader-fixture-device',
    'webdav': <String>[],
  };
  final previous = {for (final key in values.keys) key: appdata.settings[key]};
  for (final entry in values.entries) {
    appdata.settings[entry.key] = entry.value;
  }
  final local = LocalManager();
  late LocalComic comic;
  await tester.runAsync(() async {
    final dir = Directory('${root.path}/local/comic')
      ..createSync(recursive: true);
    File('${root.path}/local_path').writeAsStringSync('${root.path}/local');
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 320, 320),
      Paint()..color = Colors.orange,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 320);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    for (var i = 1; i <= 30; i++) {
      final size = imageSizes[i];
      if (size == null) {
        File('${dir.path}/$i.png').writeAsBytesSync(bytes);
      } else {
        final recorder = ui.PictureRecorder();
        Canvas(
          recorder,
        ).drawRect(Offset.zero & size, Paint()..color = Colors.orange);
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('${dir.path}/$i.png').writeAsBytesSync(data.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    }
    await local.init();
    await LocalFavoritesManager().init();
    await HistoryManager().init();
    comic = LocalComic(
      id: 'reader-fixture',
      title: 'Reader fixture',
      subtitle: '',
      tags: [],
      directory: 'comic',
      chapters: null,
      cover: '1.png',
      comicType: ComicType.local,
      downloadedChapters: [],
      createdAt: DateTime.now(),
    );
    await local.add(comic);
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    // Drain queued saves in both the fake clock and the real filesystem before
    // removing the fixture directory.
    await settle(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      local.close();
      LocalFavoritesManager().close();
      HistoryManager().close();
      await root.delete(recursive: true);
    });
    for (final entry in previous.entries) {
      appdata.settings[entry.key] = entry.value;
    }
  });
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: App.rootNavigatorKey,
      builder: (context, child) => WindowFrame(child!),
      home: Reader(
        type: ComicType.local,
        cid: comic.id,
        name: comic.title,
        chapters: null,
        initialPage: 10,
        history: History.fromModel(model: comic, ep: 1, page: 10),
        author: '',
        tags: [],
      ),
    ),
  );
  await settle(tester);
  final dynamic state = tester.state(find.byType(Reader));
  for (var i = 0; i < 20 && state.images == null; i++) {
    await settle(tester);
  }
  expect(state.images, hasLength(30));
  for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
    await settle(tester);
  }
  expect(find.byType(RawImage), findsWidgets);
  return state;
}
