part of 'favorites_page.dart';

/// Server-side search inside one network favorite folder.
///
/// Only reachable when the source implements [FavoriteData.search] or
/// [FavoriteData.searchNext]; the folder view hides its search action
/// otherwise. There is no client-side scanning of the folder pages.
class NetworkFavoritesSearchPage extends StatefulWidget {
  const NetworkFavoritesSearchPage({
    required this.data,
    required this.title,
    this.folder,
    super.key,
  });

  final FavoriteData data;

  final String title;

  /// Folder id for multi-folder sources, null otherwise.
  final String? folder;

  @override
  State<NetworkFavoritesSearchPage> createState() =>
      _NetworkFavoritesSearchPageState();
}

class _NetworkFavoritesSearchPageState
    extends State<NetworkFavoritesSearchPage> {
  final textController = TextEditingController();

  var comicListKey = GlobalKey<ComicListState>();

  String keyword = "";

  int loadedComics = 0;

  bool loadedAnyPage = false;

  /// Incremented on every submit so late responses from an old keyword cannot
  /// change the result count of the current one.
  int request = 0;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void submit([String? value]) {
    final text = (value ?? textController.text).trim();
    if (text.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      keyword = text;
      loadedComics = 0;
      loadedAnyPage = false;
      request++;
      comicListKey = GlobalKey<ComicListState>();
    });
  }

  Future<Res<List<Comic>>> _record(
    int submitted,
    Future<Res<List<Comic>>> future,
  ) async {
    final res = await future;
    if (mounted && res.success && submitted == request) {
      setState(() {
        loadedAnyPage = true;
        loadedComics += res.data.length;
      });
    }
    return res;
  }

  Widget buildSearchBar() {
    return Appbar(
      title: TextField(
        controller: textController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Search".tl,
          border: InputBorder.none,
        ),
        onSubmitted: submit,
      ),
      actions: [
        Tooltip(
          message: "Search".tl,
          child: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => submit(),
          ),
        ),
      ],
    );
  }

  Widget buildResults() {
    final data = widget.data;
    final submitted = request;
    return ComicList(
      key: comicListKey,
      loadPage: data.search == null
          ? null
          : (page) =>
                _record(submitted, data.search!(keyword, page, widget.folder)),
      loadNext: data.search != null || data.searchNext == null
          ? null
          : (next) => _record(
              submitted,
              data.searchNext!(keyword, next, widget.folder),
            ),
      menuBuilder: (comic) {
        return [
          MenuEntry(
            icon: Icons.delete_outline,
            text: "Remove".tl,
            onClick: () async {
              final removed = await _deleteComic(
                comic.id,
                null,
                comic.sourceKey,
                comic.favoriteId,
              );
              if (removed) {
                comicListKey.currentState?.remove(comic);
                setState(() {
                  loadedComics = max(0, loadedComics - 1);
                });
              }
            },
          ),
        ];
      },
      trailingSliver: loadedAnyPage && loadedComics == 0
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    "No results".tl,
                    style: TextStyle(color: context.colorScheme.outline),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildSearchBar(),
          Expanded(
            child: keyword.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        "Enter a keyword to search this folder".tl,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colorScheme.outline),
                      ),
                    ),
                  )
                : buildResults(),
          ),
        ],
      ),
    );
  }
}
