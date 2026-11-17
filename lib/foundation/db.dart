import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Opens a database that lives in the app data directory.
///
/// The default rollback journal fsyncs both the journal and the database on
/// every commit. Once another program saturates the disk those fsyncs take
/// hundreds of milliseconds, and because sqlite3 blocks the calling isolate
/// every history, favorite or cache write turns into a dropped frame. WAL keeps
/// commits in the log and `synchronous = NORMAL` only fsyncs at checkpoints, so
/// a commit still survives a process crash while the per-write stall is gone.
Database openAppDatabase(String path) {
  final db = sqlite3.open(path);
  try {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
  } catch (_) {
    // A damaged file throws here; release the handle so the caller can move
    // the file aside on platforms that lock open databases.
    db.dispose();
    rethrow;
  }
  return db;
}

/// Verifies the structure of a database once per file state.
///
/// A full `integrity_check` scans the whole file on every launch, which delays
/// startup by seconds on a busy disk. The marker records the size and mtime
/// that were already verified, so a healthy database is checked once and a
/// restored or damaged one is checked again.
bool verifyAppDatabase(Database db, String path) {
  final marker = File('$path.verified');
  final stamp = _fileStamp(path);
  if (stamp != null) {
    try {
      if (marker.readAsStringSync() == stamp) return true;
    } on FileSystemException {
      // No marker yet: fall through to the structural check.
    }
  }
  final result = db.select('PRAGMA quick_check;');
  if (result.isEmpty || result.first[0] != 'ok') return false;
  if (stamp != null) {
    try {
      // Written synchronously so the check never leaves a write in flight
      // while the data directory is being replaced or deleted.
      marker.writeAsStringSync(stamp);
    } on FileSystemException {
      // A read-only data directory only loses the shortcut.
    }
  }
  return true;
}

String? _fileStamp(String path) {
  try {
    final stat = File(path).statSync();
    return '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
  } on FileSystemException {
    return null;
  }
}
