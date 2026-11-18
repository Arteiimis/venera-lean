import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/foundation/res.dart';
import 'package:venera/pages/favorites/favorites_page.dart';

import 'support/test_translations.dart';

Comic _comic(String title) => Comic(
  title,
  'file://${Directory.current.path}/assets/app_icon.png',
  'id-$title',
  '',
  [],
  '',
  'search-test',
  null,
  null,
);

class _FakeSource implements ComicSource {
  _FakeSource(this.key, this.favoriteData);

  @override
  final String key;

  @override
  final FavoriteData favoriteData;

  @override
  String get name => key;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pumpNetworkFolder(WidgetTester tester, ComicSource source) async {
  final root = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('network-search-'),
  ))!;
  App.dataPath = root.path;
  App.cachePath = root.path;
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => root.path,
  );
  final manager = LocalFavoritesManager();
  manager.close();
  await tester.runAsync(manager.init);
  ComicSourceManager().add(source);
  appdata.implicitData['favoriteFolder'] = {
    'name': source.key,
    'isNetwork': true,
  };
  tester.view.physicalSize = const Size(1100, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    ComicSourceManager().remove(source.key);
    appdata.implicitData.remove('favoriteFolder');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    manager.close();
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  });
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: App.rootNavigatorKey,
      home: const Scaffold(body: FavoritesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await ensureTestTranslations();
    appdata.settings['showFavoriteStatusOnTile'] = false;
    appdata.settings['showHistoryStatusOnTile'] = false;
  });

  testWidgets('source search fills the results and receives the folder', (
    tester,
  ) async {
    final calls = <String>[];
    final data = FavoriteData(
      key: 'search-test',
      title: 'Search source',
      multiFolder: true,
      loadComic: null,
      loadNext: null,
      search: (keyword, page, [folder]) async {
        calls.add('$keyword|$page|$folder');
        return Res([_comic('Result $keyword')], subData: 1);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: App.rootNavigatorKey,
        home: NetworkFavoritesSearchPage(
          data: data,
          folder: 'folder-1',
          title: 'Folder',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter a keyword to search this folder'), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(find.byType(TextField), 'dragon');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(calls, ['dragon|1|folder-1']);
    expect(find.text('Result dragon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty result page reports that nothing matched', (
    tester,
  ) async {
    final data = FavoriteData(
      key: 'search-test',
      title: 'Search source',
      multiFolder: false,
      loadComic: null,
      loadNext: null,
      search: (keyword, page, [folder]) async =>
          Res(const <Comic>[], subData: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: App.rootNavigatorKey,
        home: NetworkFavoritesSearchPage(data: data, title: 'Source'),
      ),
    );
    await tester.enterText(find.byType(TextField), 'nothing');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('No results'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a source that only implements searchNext still searches', (
    tester,
  ) async {
    final calls = <String>[];
    final data = FavoriteData(
      key: 'search-test',
      title: 'Search source',
      multiFolder: false,
      loadComic: null,
      loadNext: null,
      searchNext: (keyword, next, [folder]) async {
        calls.add('$keyword|$next|$folder');
        return Res([_comic('Cursor $keyword')]);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: App.rootNavigatorKey,
        home: NetworkFavoritesSearchPage(data: data, title: 'Source'),
      ),
    );
    await tester.enterText(find.byType(TextField), 'cursor');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(calls, ['cursor|null|null']);
    expect(find.text('Cursor cursor'), findsOneWidget);
  });

  testWidgets('a folder shows search only when the source implements it', (
    tester,
  ) async {
    final source = _FakeSource(
      'search-source',
      FavoriteData(
        key: 'search-source',
        title: 'Search source',
        multiFolder: false,
        loadComic: (page, [folder]) async =>
            Res([_comic('Folder comic')], subData: 1),
        loadNext: null,
        search: (keyword, page, [folder]) async =>
            Res([_comic('Search $keyword')], subData: 1),
      ),
    );
    await _pumpNetworkFolder(tester, source);

    expect(find.text('Folder comic'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Enter a keyword to search this folder'), findsOneWidget);
  });

  testWidgets('a folder without source search has no search action', (
    tester,
  ) async {
    final source = _FakeSource(
      'plain-source',
      FavoriteData(
        key: 'plain-source',
        title: 'Plain source',
        multiFolder: false,
        loadComic: (page, [folder]) async =>
            Res([_comic('Plain comic')], subData: 1),
        loadNext: null,
      ),
    );
    await _pumpNetworkFolder(tester, source);

    expect(find.text('Plain comic'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
  });
}
