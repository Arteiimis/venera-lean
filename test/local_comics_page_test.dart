import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/components/components.dart';
import 'package:venera/components/window_frame.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/local.dart';
import 'package:venera/pages/local_comics_page.dart';
import 'package:venera/pages/reader/reader.dart';
import 'support/reader_fixture.dart' as fixture;

void main() {
  testWidgets(
    'local library shows size, manages categories and opens the reader on tap',
    (tester) async {
      await fixture.openReader(tester, 'galleryLeftToRight');
      await tester.pumpWidget(const SizedBox());
      await fixture.settle(tester);
      final local = LocalManager();
      final comic = local.getComics(LocalSortType.name).single;
      await tester.runAsync(() async {
        for (final id in ['first', 'second']) {
          Directory('${comic.baseDir}/$id').createSync();
          File('${comic.baseDir}/1.png').copySync('${comic.baseDir}/$id/1.png');
        }
        await local.add(
          LocalComic(
            id: comic.id,
            title: comic.title,
            subtitle: '',
            tags: [],
            directory: comic.directory,
            chapters: ComicChapters({
              'first': 'First chapter',
              'second': 'Second chapter',
            }),
            cover: comic.cover,
            comicType: ComicType.local,
            downloadedChapters: ['first', 'second'],
            createdAt: comic.createdAt,
          ),
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: App.rootNavigatorKey,
          builder: (context, child) => WindowFrame(child!),
          home: const LocalComicsPage(),
        ),
      );
      await fixture.settle(tester);
      expect(find.textContaining('Local · '), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(MenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New folder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Offline');
      await tester.tap(find.text('Save'));
      await fixture.settle(tester);
      expect(local.library.folders.single.name, 'Offline');
      await tester.longPress(find.text('Reader fixture'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to folder'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Offline'),
        ),
      );
      await fixture.settle(tester);
      expect(
        local.library.placements[(comic.id, 0)]?.folder,
        local.library.folders.single.id,
      );
      // Exit selection and filter the category.
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline'));
      await fixture.settle(tester);

      // A plain tap opens the reader immediately, without a choice dialog.
      await tester.tap(find.text('Reader fixture'));
      await fixture.settle(tester);
      expect(tester.widget<Reader>(find.byType(Reader)).initialChapter, 1);
      expect(find.byType(SimpleDialog), findsNothing);
      expect(tester.takeException(), isNull);

      // Details and its chapters stay in the right-click menu.
      await tester.pumpWidget(const SizedBox());
      await fixture.settle(tester);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: App.rootNavigatorKey,
          builder: (context, child) => WindowFrame(child!),
          home: const LocalComicsPage(),
        ),
      );
      await fixture.settle(tester);
      await tester.tap(find.text('Offline'));
      await fixture.settle(tester);
      await tester.tap(find.text('Reader fixture'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Move to folder'), findsOneWidget);
      expect(find.text('View Detail'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      await fixture.settle(tester);
    },
  );
}
