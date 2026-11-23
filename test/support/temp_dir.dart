import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Removes a temporary data directory once nothing holds a file inside it.
///
/// Widget tests start real file reads under the fake clock, and sqlite keeps
/// its database open until the manager is closed. On Windows either handle
/// makes the deletion fail with a sharing violation (errno 32) or leaves the
/// directory non-empty (errno 145), while POSIX simply unlinks open files, so
/// a test that passes in Linux CI can fail on a Windows desktop. Real time is
/// pumped between attempts so pending reads complete and closes land.
Future<void> deleteTempDirectory(WidgetTester tester, Directory root) async {
  for (var attempt = 1; ; attempt++) {
    // runAsync reports a callback's exception on the test instead of
    // rethrowing it, so the outcome has to travel out of the callback.
    FileSystemException? failure;
    await tester.runAsync(() async {
      try {
        await root.delete(recursive: true);
      } on FileSystemException catch (e) {
        failure = e;
      }
    });
    final error = failure;
    if (error == null) return;
    if (attempt >= 10) {
      throw StateError('Temporary directory stays locked: ${error.message}');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The same retries for plain tests that have no widget tester to pump.
Future<void> deleteEventually(Directory directory) async {
  for (var attempt = 1; ; attempt++) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      if (attempt >= 10) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
