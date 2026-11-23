import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tile badges read page info once and follow later changes', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('history-badge-'),
    ))!;
    App.dataPath = root.path;
    addTearDown(() {
      HistoryManager().close();
      root.deleteSync(recursive: true);
    });
    await tester.runAsync(() => HistoryManager().init());

    void add(String id, int page, int? maxPage) {
      HistoryManager().addHistory(
        History.fromMap({
          'id': id,
          'type': ComicType.local.value,
          'title': id,
          'subtitle': '',
          'cover': '',
          'time': DateTime(2026, 1, 1).millisecondsSinceEpoch,
          'ep': 1,
          'page': page,
          'max_page': maxPage,
        }),
      );
    }

    add('reading', 3, 9);
    add('finished', 9, 9);
    add('unknown-length', 2, null);

    final reading = HistoryManager().badge('reading', ComicType.local)!;
    expect((reading.page, reading.maxPage), (3, 9));
    final finished = HistoryManager().badge('finished', ComicType.local)!;
    expect((finished.page, finished.maxPage), (9, 9));
    final unknown = HistoryManager().badge('unknown-length', ComicType.local)!;
    expect((unknown.page, unknown.maxPage), (2, null));
    expect(HistoryManager().badge('missing', ComicType.local), isNull);
    // The same id on another source is a different history entry.
    expect(HistoryManager().badge('reading', const ComicType(42)), isNull);

    // Reading further replaces the cached badge instead of serving the old one.
    add('reading', 7, 9);
    expect(HistoryManager().badge('reading', ComicType.local)!.page, 7);

    // Removing the row drops the badge.
    HistoryManager().remove('reading', ComicType.local);
    expect(HistoryManager().badge('reading', ComicType.local), isNull);
  });

  testWidgets('history database has an index for ordering by time', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('history-index-'),
    ))!;
    App.dataPath = root.path;
    addTearDown(() {
      HistoryManager().close();
      root.deleteSync(recursive: true);
    });
    await tester.runAsync(() => HistoryManager().init());
    await tester.runAsync(() async => HistoryManager().close());

    final db = sqlite3.open('${root.path}/history.db', mode: OpenMode.readOnly);
    try {
      final indexes = db
          .select(
            "select name from sqlite_master where type = 'index' and tbl_name = 'history';",
          )
          .map((row) => row['name'] as String);
      expect(indexes, contains('history_time'));
    } finally {
      db.dispose();
    }
  });
}
