import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/components/components.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';

import 'support/test_translations.dart';

Comic _comic() => Comic(
  'Local comic',
  'file://${Directory.current.path}/assets/app_icon.png',
  'local-comic',
  '',
  [],
  '',
  'test',
  null,
  null,
);

Widget _host(Comic comic, Widget Function() footer) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 420,
        height: 160,
        child: ComicTile(comic: comic, footer: footer),
      ),
    ),
  ),
);

void main() {
  setUp(() async {
    await ensureTestTranslations();
    appdata.settings['showFavoriteStatusOnTile'] = false;
    appdata.settings['showHistoryStatusOnTile'] = false;
  });

  testWidgets('detailed mode renders the footer at the card bottom-right', (
    tester,
  ) async {
    appdata.settings['comicDisplayMode'] = 'detailed';
    var calls = 0;
    await tester.pumpWidget(
      _host(_comic(), () {
        calls++;
        return const Text('Local · 1 MB');
      }),
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Local · 1 MB'), findsOneWidget);

    // The label lives in the description column on the right, not on the cover.
    final tile = tester.getRect(find.byType(ComicTile));
    final footer = tester.getRect(find.text('Local · 1 MB'));
    expect(footer.center.dx, greaterThan(tile.left + tile.width * 0.6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('brief mode never builds or shows the footer', (tester) async {
    appdata.settings['comicDisplayMode'] = 'brief';
    var calls = 0;
    await tester.pumpWidget(
      _host(_comic(), () {
        calls++;
        return const Text('Local · 1 MB');
      }),
    );
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text('Local · 1 MB'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
