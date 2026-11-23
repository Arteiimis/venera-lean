import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/local.dart';

void main() {
  test('adds description to an older local database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'venera-local-migration-',
    );
    final comicDirectory = Directory('${directory.path}/local')..createSync();
    App.dataPath = directory.path;
    File('${directory.path}/local_path').writeAsStringSync(comicDirectory.path);

    final db = sqlite3.open('${directory.path}/local.db');
    db.execute('''
      CREATE TABLE comics (
        id TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        tags TEXT NOT NULL,
        directory TEXT NOT NULL,
        chapters TEXT NOT NULL,
        cover TEXT NOT NULL,
        comic_type INTEGER NOT NULL,
        downloadedChapters TEXT NOT NULL,
        created_at INTEGER,
        PRIMARY KEY (id, comic_type)
      );
    ''');
    db.execute(
      '''INSERT INTO comics
         (id, title, subtitle, tags, directory, chapters, cover,
          comic_type, downloadedChapters, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);''',
      [
        '1',
        'Legacy local comic',
        'Author',
        jsonEncode(['tag']),
        'Legacy local comic',
        'null',
        'cover.jpg',
        ComicType.local.value,
        '[]',
        1,
      ],
    );
    db.dispose();

    final manager = LocalManager();
    manager.close();
    await manager.init();
    final comic = manager.find('1', ComicType.local);
    expect(comic, isNotNull);
    expect(comic!.description, isEmpty);
    final migratedDb = sqlite3.open('${directory.path}/local.db');
    expect(
      migratedDb
          .select('PRAGMA table_info(comics);')
          .any((row) => row['name'] == 'description'),
      isTrue,
    );
    migratedDb.dispose();
    manager.close();
    await directory.delete(recursive: true);
  });

  test('adds size columns to a database from the previous release', () async {
    final directory = await Directory.systemTemp.createTemp(
      'venera-local-migration-',
    );
    final comicDirectory = Directory('${directory.path}/local')..createSync();
    App.dataPath = directory.path;
    File('${directory.path}/local_path').writeAsStringSync(comicDirectory.path);

    final db = sqlite3.open('${directory.path}/local.db');
    db.execute('''
      CREATE TABLE comics (
        id TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL,
        directory TEXT NOT NULL,
        chapters TEXT NOT NULL,
        cover TEXT NOT NULL,
        comic_type INTEGER NOT NULL,
        downloadedChapters TEXT NOT NULL,
        created_at INTEGER,
        managed_by_app INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (id, comic_type)
      );
    ''');
    db.execute(
      'INSERT INTO comics VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        '2',
        'Local comic',
        '',
        '',
        jsonEncode([]),
        'Local comic',
        'null',
        'cover.jpg',
        ComicType.local.value,
        '[]',
        1,
        1,
      ],
    );
    db.dispose();

    final manager = LocalManager();
    manager.close();
    await manager.init();
    final comic = manager.find('2', ComicType.local);
    expect(comic, isNotNull);
    expect(comic!.sizeBytes, isNull);
    expect(comic.sizeCheckedAt, isNull);
    expect(LocalManager.hasFreshSize(comic), isFalse);
    manager.setSize('2', ComicType.local, 1234);
    final sized = manager.find('2', ComicType.local)!;
    expect(sized.sizeBytes, 1234);
    expect(LocalManager.hasFreshSize(sized), isTrue);
    final migratedDb = sqlite3.open('${directory.path}/local.db');
    final columns = migratedDb
        .select('PRAGMA table_info(comics);')
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['size_bytes', 'size_checked_at']));
    migratedDb.dispose();
    manager.close();
    await directory.delete(recursive: true);
  });
}
