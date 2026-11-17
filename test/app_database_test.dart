import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:venera/foundation/db.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('app-database-');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('app databases commit through a write-ahead log', () {
    final path = '${directory.path}/history.db';
    final db = openAppDatabase(path);
    addTearDown(db.dispose);

    expect(db.select('PRAGMA journal_mode;').first[0], 'wal');
    // 1 == NORMAL: commits no longer fsync on every write.
    expect(db.select('PRAGMA synchronous;').first[0], 1);
    expect(db.select('PRAGMA busy_timeout;').first[0], 5000);

    db.execute('CREATE TABLE history (id TEXT);');
    db.execute('INSERT INTO history VALUES (?)', ['comic']);
    expect(db.select('SELECT id FROM history;').first[0], 'comic');
  });

  test('verification succeeds once and records the verified file state', () {
    final path = '${directory.path}/local_favorite.db';
    final db = openAppDatabase(path);
    addTearDown(db.dispose);
    db.execute('CREATE TABLE favorites (id TEXT);');

    expect(verifyAppDatabase(db, path), isTrue);
    final stat = File(path).statSync();
    final marker = File('$path.verified');
    final expected = '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
    expect(marker.readAsStringSync(), expected);
    // A matching marker short-circuits the structural scan.
    expect(verifyAppDatabase(db, path), isTrue);
  });

  test('a damaged database cannot be opened as an app database', () {
    final path = '${directory.path}/read_later.db';
    File(path).writeAsStringSync('not a sqlite database');

    expect(() => openAppDatabase(path), throwsA(isA<SqliteException>()));
  });
}
