import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/utils/comic_search.dart';
import 'package:venera/utils/opencc.dart';
import 'package:venera/utils/tags_translation.dart';

const _texts = [
  ComicSearchText(
    title: '夏日回憶',
    subtitle: 'Alice',
    tags: ['female:sole female', 'glasses'],
  ),
  ComicSearchText(
    title: 'Summer Days 2',
    subtitle: 'Bob',
    tags: ['other:full color'],
  ),
  ComicSearchText(
    title: '學園祭の夜',
    subtitle: 'Alice',
    tags: ['language:chinese'],
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    appdata.settings['language'] = 'zh-CN';
    await OpenCC.init();
    await TagsTranslation.readData();
  });

  group('favorite search index', () {
    FavoriteSearchIndex index() => FavoriteSearchIndex(_texts);

    test('empty query returns every comic', () {
      final search = index();
      expect(search.filter(''), [0, 1, 2]);
      expect(search.filter('   '), [0, 1, 2]);
    });

    test('title and subtitle match by substring', () {
      final search = index();
      expect(search.filter('夏日'), [0]);
      expect(search.filter('summer'), [1]);
      expect(search.filter('Summer'), [1]);
      expect(search.filter('alice'), [0, 2]);
      expect(search.filter('ali'), [0, 2]);
    });

    test('a query with a capital is case sensitive', () {
      final search = index();
      expect(search.filter('SUMMER'), isEmpty);
      expect(search.filter('Summer'), [1]);
    });

    test('tags match by exact value, namespace segment and translation', () {
      final search = index();
      expect(search.filter('glasses'), [0]);
      // Tags never matched by substring, which is how the page behaved.
      expect(search.filter('glass'), isEmpty);
      expect(search.filter('chinese'), [2]);
      expect(search.filter('汉语'), [2]);
      expect(search.filter('单女主'), [0]);
      expect(search.filter('眼镜👓'), [0]);
      // A multi-word namespace segment cannot be typed as one token.
      expect(search.filter('sole'), isEmpty);
    });

    test('tokens are combined with AND', () {
      final search = index();
      expect(search.filter('summer 2'), [1]);
      expect(search.filter('summer alice'), isEmpty);
    });

    test('simplified and traditional queries match each other', () {
      final search = index();
      expect(search.filter('学园'), [2]);
      expect(search.filter('學園'), [2]);
    });

    test('explicit translations do not depend on the locale', () {
      final search = FavoriteSearchIndex(const [
        ComicSearchText(
          title: 'Tagged',
          tags: ['female:sole female'],
          translatedTags: ['单女主'],
        ),
        ComicSearchText(title: 'Other', tags: ['female:sole male']),
      ]);
      expect(search.filter('单女主'), [0]);
    });
  });

  group('library search index', () {
    LibrarySearchIndex index() => LibrarySearchIndex(_texts);

    test('matches the whole keyword inside one field', () {
      final search = index();
      expect(search.filter('夏日'), [0]);
      expect(search.filter('summer'), [1]);
      expect(search.filter('Summer Days'), [1]);
      // The old SQL search did not split the keyword on spaces.
      expect(search.filter('summer 2'), isEmpty);
      expect(search.filter(''), [0, 1, 2]);
    });

    test('matches tag substrings without translations', () {
      final search = index();
      expect(search.filter('lass'), [0]);
      expect(search.filter('full color'), [1]);
      expect(search.filter('单女主'), isEmpty);
    });
  });

  test('favorite index agrees with the legacy matcher', () {
    final comics = [
      for (var i = 0; i < _texts.length; i++)
        FavoriteItem(
          id: 'id$i',
          name: _texts[i].title,
          coverPath: '',
          author: _texts[i].subtitle,
          type: const ComicType(42),
          tags: _texts[i].tags,
        ),
    ];
    final index = FavoriteSearchIndex(_texts);
    const queries = [
      '',
      ' ',
      '夏日',
      '學園',
      '学园',
      'summer',
      'Summer',
      'SUMMER',
      'alice',
      'ALICE',
      'glasses',
      'GLASSES',
      'glass',
      'chinese',
      '汉语',
      '单女主',
      '眼镜👓',
      'summer 2',
      'summer days 2',
      'bob x',
    ];
    for (final query in queries) {
      final expected = [
        for (var i = 0; i < comics.length; i++)
          if (_legacyMatches(query, comics[i])) i,
      ];
      expect(index.filter(query), expected, reason: 'query: "$query"');
    }
  });
}

// The matcher that lived in the favorites page before the index, kept here as
// the reference for the parity test above.
bool _legacyMatches(String keyword, FavoriteItem comic) {
  final searchHasUpper = keyword.contains(RegExp(r'[A-Z]'));
  bool check(String keyword, String compare, bool needEqual) {
    var temp = compare;
    if (!searchHasUpper) {
      temp = temp.toLowerCase();
    }
    return needEqual ? keyword == temp : temp.contains(keyword);
  }

  bool match(String keyword) {
    for (final k in keyword.split(" ")) {
      if (k.isEmpty) continue;
      if (check(k, comic.title, false)) continue;
      if (comic.subtitle != null && check(k, comic.subtitle!, false)) continue;
      if (comic.tags.any((tag) {
        if (check(k, tag, true)) return true;
        if (tag.contains(':') && check(k, tag.split(':')[1], true)) return true;
        if (check(k, tag.translateTagsToCN, true)) return true;
        return false;
      })) {
        continue;
      }
      if (check(k, comic.author, true)) continue;
      return false;
    }
    return true;
  }

  if (match(keyword)) {
    return true;
  }
  if (OpenCC.hasChineseSimplified(keyword) &&
      match(OpenCC.simplifiedToTraditional(keyword))) {
    return true;
  }
  if (OpenCC.hasChineseTraditional(keyword) &&
      match(OpenCC.traditionalToSimplified(keyword))) {
    return true;
  }
  return false;
}
