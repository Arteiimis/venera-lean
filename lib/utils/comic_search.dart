import 'package:venera/foundation/app.dart';
import 'package:venera/utils/opencc.dart';
import 'package:venera/utils/tags_translation.dart';

/// The text of one comic that the search indexes need.
class ComicSearchText {
  const ComicSearchText({
    required this.title,
    this.subtitle = '',
    this.tags = const [],
    this.translatedTags,
  });

  final String title;

  final String subtitle;

  final List<String> tags;

  /// Tag translations parallel to [tags].
  ///
  /// When null, [FavoriteSearchIndex] translates tags with [TagsTranslation]
  /// on non-English locales. An empty list disables translation matching.
  final List<String>? translatedTags;
}

/// Pre-indexed text for favorite search.
///
/// Matching keeps the rules the favorites page has always used:
/// - tokens are split on spaces and combined with AND;
/// - title and subtitle match by substring;
/// - tags match by exact value, by the part after the first colon, or by their
///   Chinese translation;
/// - matching ignores case unless the query contains an ASCII capital;
/// - a simplified query also matches traditional text and the other way round.
class FavoriteSearchIndex {
  FavoriteSearchIndex(List<ComicSearchText> entries)
    : _entries = [for (final entry in entries) _FavoriteEntry(entry)];

  final List<_FavoriteEntry> _entries;

  static final _asciiCapital = RegExp(r'[A-Z]');

  /// Indices of the matching entries, in the input order.
  List<int> filter(String query) {
    if (query.trim().isEmpty) {
      return List<int>.generate(_entries.length, (index) => index);
    }
    final hasCapital = _asciiCapital.hasMatch(query);
    final variants = <List<String>>[];
    void addVariant(String text) {
      final tokens = [
        for (final token in text.split(' '))
          if (token.isNotEmpty) token,
      ];
      if (tokens.isNotEmpty) {
        variants.add(tokens);
      }
    }

    addVariant(query);
    // A token converted once per query instead of once per comic.
    if (OpenCC.hasChineseSimplified(query)) {
      addVariant(OpenCC.simplifiedToTraditional(query));
    }
    if (OpenCC.hasChineseTraditional(query)) {
      addVariant(OpenCC.traditionalToSimplified(query));
    }

    final result = <int>[];
    for (var index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      for (final tokens in variants) {
        if (entry.matches(tokens, hasCapital)) {
          result.add(index);
          break;
        }
      }
    }
    return result;
  }
}

class _FavoriteEntry {
  _FavoriteEntry(ComicSearchText text)
    : title = text.title,
      subtitle = text.subtitle,
      tags = text.tags,
      titleLower = text.title.toLowerCase(),
      subtitleLower = text.subtitle.toLowerCase(),
      translateTags =
          text.translatedTags != null || App.locale.languageCode != 'en' {
    final translated = text.translatedTags;
    final values = <String>{};
    for (var i = 0; i < text.tags.length; i++) {
      final tag = text.tags[i];
      values.add(tag.toLowerCase());
      final part = _tagPart(tag);
      if (part != null) {
        values.add(part.toLowerCase());
      }
      if (translateTags) {
        final value = translated != null
            ? (i < translated.length ? translated[i] : tag)
            : _translateTag(tag);
        values.add(value.toLowerCase());
      }
    }
    tagValuesLower = values.toList(growable: false);
  }

  final String title;

  final String subtitle;

  final List<String> tags;

  final String titleLower;

  final String subtitleLower;

  final bool translateTags;

  late final List<String> tagValuesLower;

  bool matches(List<String> tokens, bool hasCapital) {
    for (final token in tokens) {
      if ((hasCapital ? title : titleLower).contains(token)) {
        continue;
      }
      if ((hasCapital ? subtitle : subtitleLower).contains(token)) {
        continue;
      }
      if (hasCapital ? _matchesRawTag(token) : tagValuesLower.contains(token)) {
        continue;
      }
      return false;
    }
    return true;
  }

  bool _matchesRawTag(String token) {
    for (final tag in tags) {
      if (tag == token) {
        return true;
      }
      final part = _tagPart(tag);
      if (part == token) {
        return true;
      }
      if (translateTags && _translateTag(tag) == token) {
        return true;
      }
    }
    return false;
  }

  /// The segment after the first colon, matching `tag.split(':')[1]`.
  static String? _tagPart(String tag) {
    final colon = tag.indexOf(':');
    if (colon < 0) {
      return null;
    }
    final next = tag.indexOf(':', colon + 1);
    return tag.substring(colon + 1, next < 0 ? tag.length : next);
  }
}

/// The tag vocabulary is shared by many comics, so translating each distinct
/// tag once keeps index builds and capitalized queries cheap.
final Map<String, String> _tagTranslations = {};

String _translateTag(String tag) =>
    _tagTranslations[tag] ??= tag.translateTagsToCN;

/// Pre-indexed text for the local library search.
///
/// Mirrors the old `title LIKE ? OR subtitle LIKE ? OR tags LIKE ?` scan: the
/// whole keyword has to appear in one field, ASCII case-insensitively.
class LibrarySearchIndex {
  LibrarySearchIndex(List<ComicSearchText> entries)
    : _titles = [for (final entry in entries) entry.title.toLowerCase()],
      _subtitles = [for (final entry in entries) entry.subtitle.toLowerCase()],
      _tags = [
        for (final entry in entries)
          [for (final tag in entry.tags) tag.toLowerCase()],
      ];

  final List<String> _titles;

  final List<String> _subtitles;

  final List<List<String>> _tags;

  /// Indices of the matching entries, in the input order.
  List<int> filter(String query) {
    if (query.isEmpty) {
      return List<int>.generate(_titles.length, (index) => index);
    }
    final keyword = query.toLowerCase();
    final result = <int>[];
    for (var index = 0; index < _titles.length; index++) {
      if (_titles[index].contains(keyword) ||
          _subtitles[index].contains(keyword) ||
          _tags[index].any((tag) => tag.contains(keyword))) {
        result.add(index);
      }
    }
    return result;
  }
}
