import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/local.dart';
import 'package:venera/utils/io.dart';

LocalComic _comic(String id, String directory) => LocalComic(
  id: id,
  title: 'Comic $id',
  subtitle: '',
  tags: [],
  directory: directory,
  chapters: null,
  cover: 'cover.png',
  comicType: ComicType.local,
  downloadedChapters: [],
  createdAt: DateTime(2026),
);

void _write(Directory dir, String relativePath, int bytes) {
  final file = File('${dir.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(List.filled(bytes, 0));
}

void main() {
  late Directory root;
  late Directory library;
  late LocalManager manager;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('venera-local-size-');
    library = Directory('${root.path}/local')..createSync();
    File('${root.path}/local_path').writeAsStringSync(library.path);
    App.dataPath = root.path;
    manager = LocalManager();
    manager.close();
    await manager.init();
  });

  tearDown(() async {
    manager.close();
    await root.delete(recursive: true);
  });

  test(
    'directorySizeIsolate sums nested files without following links',
    () async {
      final comic = Directory('${library.path}/a')..createSync();
      _write(comic, '1.bin', 100);
      _write(comic, 'ch1/2.bin', 250);
      _write(comic, 'ch1/deep/3.bin', 7);
      Directory('${library.path}/empty').createSync();
      final outside = Directory('${root.path}/outside')..createSync();
      _write(outside, 'big.bin', 5000);
      Link? link;
      try {
        link = Link('${comic.path}/linked')..createSync(outside.path);
      } on FileSystemException {
        // Creating links needs a privilege this machine does not grant.
      }

      expect(await directorySizeIsolate(comic.path), 357);
      expect(await directorySizeIsolate('${library.path}/empty'), 0);
      expect(
        () => directorySizeIsolate('${library.path}/missing'),
        throwsA(isA<FileSystemException>()),
      );
      if (link != null) {
        expect(link.existsSync(), isTrue);
      }
    },
  );

  test(
    'measured sizes persist, expire after the TTL and reset on write',
    () async {
      final comic = Directory('${library.path}/a')..createSync();
      _write(comic, '1.bin', 4096);
      await manager.add(_comic('1', 'a'));
      expect(manager.find('1', ComicType.local)!.sizeBytes, isNull);

      expect(
        await manager.measureSize(manager.find('1', ComicType.local)!),
        4096,
      );
      final stored = manager.find('1', ComicType.local)!;
      expect(stored.sizeBytes, 4096);
      final checkedAt = stored.sizeCheckedAt!;
      expect(LocalManager.hasFreshSize(stored, now: checkedAt), isTrue);
      expect(
        LocalManager.hasFreshSize(
          stored,
          now: checkedAt.add(
            LocalManager.sizeCacheTtl - const Duration(seconds: 1),
          ),
        ),
        isTrue,
      );
      expect(
        LocalManager.hasFreshSize(
          stored,
          now: checkedAt.add(LocalManager.sizeCacheTtl),
        ),
        isFalse,
      );

      // Any write may have changed the files, so the size is forgotten.
      await manager.add(_comic('1', 'a'));
      final rewritten = manager.find('1', ComicType.local)!;
      expect(rewritten.sizeBytes, isNull);
      expect(LocalManager.hasFreshSize(rewritten, now: checkedAt), isFalse);

      // A vanished directory reports an error instead of a plausible zero.
      await comic.delete(recursive: true);
      await expectLater(
        manager.measureSize(rewritten),
        throwsA(isA<FileSystemException>()),
      );
      expect(manager.find('1', ComicType.local)!.sizeBytes, isNull);
    },
  );
}
