import 'package:flutter_test/flutter_test.dart';
import 'package:venera/utils/data_sync.dart';

void main() {
  test('orders backup revisions before device dates across digit changes', () {
    final names = [
      'lean-20000-9.venera',
      'lean-20000-10.venera',
      'lean-9999-99999.venera',
      'lean-20000-3687.venera',
      'lean-20000-10000.venera',
      'lean-20000-9999.venera',
    ]..sort(compareBackupNames);
    expect(names, [
      'lean-20000-9.venera',
      'lean-20000-10.venera',
      'lean-20000-3687.venera',
      'lean-20000-9999.venera',
      'lean-20000-10000.venera',
      'lean-9999-99999.venera',
    ]);
  });

  test('clock rollback cannot hide or prune a newer revision', () {
    expect(
      compareBackupNames('lean-20000-11.venera', 'lean-20001-10.venera'),
      greaterThan(0),
    );
    expect(nextBackupVersion(8, ['lean-20001-10.venera']), 11);
    final prune = backupFilesToPrune(
      existingNames: [
        'lean-20001-10.venera',
        for (var i = 11; i <= 19; i++) 'lean-20000-$i.venera',
      ],
      dayPrefix: 'lean-19999-',
      uploadedFilename: 'lean-19999-20.venera',
    );
    expect(prune, ['lean-20001-10.venera']);
  });

  test('a device importing version 3687 advances past other devices', () {
    expect(nextBackupVersion(3687, ['lean-20000-4000.venera']), 4001);
    expect(nextBackupVersion(5000, ['lean-20000-4000.venera']), 5001);
  });

  test('concurrent snapshots with equal counters have a stable order', () {
    expect(
      compareBackupNames(
        'lean-20000-8-0001-a.venera',
        'lean-20000-8-0002-b.venera',
      ),
      lessThan(0),
    );
    expect(nextBackupVersion(7, ['lean-20000-8-0002-b.venera']), 9);
  });

  test('pruning keeps equal-counter and newer concurrent snapshots', () {
    expect(
      backupFilesToPrune(
        existingNames: [
          'lean-20000-7.venera',
          'lean-20000-8-0001-a.venera',
          'lean-20000-9-0003-c.venera',
        ],
        dayPrefix: 'lean-20000-',
        uploadedFilename: 'lean-20000-8-0002-b.venera',
      ),
      ['lean-20000-7.venera'],
    );
  });

  test(
    'does not prune the file just uploaded when its name already exists',
    () {
      final prune = backupFilesToPrune(
        existingNames: [
          'lean-20000-4.venera',
          'lean-20000-5.venera',
          'lean-19999-9.venera',
        ],
        dayPrefix: 'lean-20000-',
        uploadedFilename: 'lean-20000-5.venera',
      );

      expect(prune, ['lean-20000-4.venera']);
      expect(prune, isNot(contains('lean-20000-5.venera')));
    },
  );

  test('prunes the oldest remaining backup only when over the limit', () {
    final prune = backupFilesToPrune(
      existingNames: [
        'lean-19990-1.venera',
        'lean-19991-1.venera',
        'lean-19992-1.venera',
        'lean-19993-1.venera',
        'lean-19994-1.venera',
        'lean-19995-1.venera',
        'lean-19996-1.venera',
        'lean-19997-1.venera',
        'lean-19998-1.venera',
        'lean-19999-1.venera',
      ],
      dayPrefix: 'lean-20000-',
      uploadedFilename: 'lean-20000-1.venera',
    );

    expect(prune, ['lean-19990-1.venera']);
    expect(prune, isNot(contains('lean-20000-1.venera')));
  });

  test(
    'prunes every excess backup when the existing set is over the limit',
    () {
      final prune = backupFilesToPrune(
        existingNames: List.generate(
          11,
          (index) => 'lean-${19989 + index}-1.venera',
        ),
        dayPrefix: 'lean-20000-',
        uploadedFilename: 'lean-20000-1.venera',
      );

      expect(prune, ['lean-19989-1.venera', 'lean-19990-1.venera']);
    },
  );

  test('retains prior files when ten or fewer remain after upload', () {
    final prune = backupFilesToPrune(
      existingNames: List.generate(9, (index) => 'lean-1999$index-1.venera'),
      dayPrefix: 'lean-20000-',
      uploadedFilename: 'lean-20000-1.venera',
    );

    expect(prune, isEmpty);
  });
}
