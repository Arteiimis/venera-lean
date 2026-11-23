import 'dart:convert';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/cache_manager.dart';
import 'package:venera/foundation/image_provider/reader_image.dart';
import 'package:venera/network/app_dio.dart';
import 'package:venera/network/images.dart';
import 'package:venera/pages/reader/reader.dart';

import 'support/temp_dir.dart';

void main() {
  testWidgets('reload of a resized reader image replaces its disk cache', (
    tester,
  ) async {
    late Directory root;
    late HttpServer server;
    var requests = 0;
    var ready = 0;
    // flutter_test replaces HttpClient with a stub that answers 400 and never
    // reaches the network; this test needs the real loopback server.
    HttpOverrides.global = null;
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
    );
    final fresh = [...png, 42];
    late String url;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('reader-reload-');
      App.dataPath = root.path;
      App.cachePath = root.path;
      CacheManager.instance = null;
      // The native rhttp library is not loadable inside flutter test; the
      // reload under test only needs any HTTP transport.
      AppDio.adapterOverride = () => IOHttpClientAdapter();
      appdata.settings['proxy'] = 'direct';
      appdata.settings['enableCustomImageProcessing'] = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests++;
        request.response.add(fresh);
        await request.response.close();
      });
      url = 'http://127.0.0.1:${server.port}/page.png';
      await CacheManager().writeCache('$url@null@c@e', png);
    });
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ComicImage(
            image: ReaderImageProvider(url, null, 'c', 'e', 1),
            cacheWidth: 1,
            onImageReady: () => ready++,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      for (var i = 0; i < 30 && ready == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready, greaterThan(0));
      expect(requests, 0);
      final dynamic state = tester.state(find.byType(ComicImage));
      var reloaded = false;
      state.reload().then((_) {
        reloaded = true;
      });
      for (var i = 0; i < 50 && (!reloaded || requests == 0); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(requests, 1);
      for (var i = 0; i < 50 && ready < 2; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready, 2);
      await tester.runAsync(() async {
        for (var i = 0; i < 30; i++) {
          if (await CacheManager().readCache('$url@null@c@e') != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(await CacheManager().readCache('$url@null@c@e'), fresh);
      });
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        ImageDownloader.cancelAllLoadingImages();
        await server.close(force: true);
      });
      // cache.db stays open otherwise, and Windows then refuses the delete.
      // close() waits for queued cache work, which resumes on this test's
      // fake clock, so pump real time until it completes.
      var closed = false;
      CacheManager.instance?.close().whenComplete(() => closed = true);
      for (var i = 0; i < 20 && !closed; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(closed, isTrue, reason: 'CacheManager.close() did not finish');
      CacheManager.instance = null;
      AppDio.adapterOverride = null;
      await deleteTempDirectory(tester, root);
    }
  });
}
