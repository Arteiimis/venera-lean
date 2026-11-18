import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('read completion marks comics whose last page was read', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('read-completion-'),
    ))!;
    App.dataPath = root.path;
    addTearDown(() {
      HistoryManager().close();
      root.deleteSync(recursive: true);
    });
    await tester.runAsync(() => HistoryManager().init());

    void add(String id, ComicType type, int page, int? maxPage) {
      HistoryManager().addHistory(
        History.fromMap({
          'id': id,
          'type': type.value,
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

    add('finished', ComicType.local, 5, 5);
    add('reading', ComicType.local, 3, 5);
    add('unknown-length', const ComicType(42), 2, null);

    final completion = HistoryManager().readCompletion();
    expect(completion.isCompleted('finished', ComicType.local), isTrue);
    expect(completion.isCompleted('reading', ComicType.local), isFalse);
    expect(
      completion.isCompleted('unknown-length', const ComicType(42)),
      isFalse,
    );
    expect(completion.isCompleted('missing', ComicType.local), isFalse);
    // The same comic id on another source is a different history entry.
    expect(completion.isCompleted('finished', const ComicType(42)), isFalse);
    expect(HistoryManager().readCompletion().sameAs(completion), isTrue);
  });
}
