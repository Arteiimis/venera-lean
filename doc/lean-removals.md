# Venera Lean 精简台账

本仓库相对上游 venera-app/venera-prime 的功能删除记录。同步上游时用本表判断冲突该往哪边落：`git diff upstream-master` 应始终等于本表的累积结果。

## 约定

- 整文件删除优先，其次摘入口（导航项、设置项、首页模块、CLI 子命令、阅读器工具栏按钮），避免在大文件里挖洞。上游改动频繁的文件（统计自 `upstream-master`）：`lib/foundation/appdata.dart` 95 次提交、`lib/pages/reader/images.dart` 81、`lib/pages/reader/scaffold.dart` 67、`lib/pages/home_page.dart` 62、`lib/foundation/favorites.dart` 40、`lib/pages/settings/reader.dart` 37——每次同步都要过一遍。
- 保留数据库 schema 与既有列，只删读写逻辑：旧数据库文件与上游备份继续能打开，避免用户数据迁移。
- `assets/translation.json` 不删键：死字符串无害，删键会在频繁改动的该文件里制造冲突。
- 每项功能一次提交，提交前跑 `fvm flutter analyze` 与受影响测试。

## 批次 1

### 百宝箱（Toolbox）

- 删除：`lib/pages/toolbox.dart` 整文件（142 行）；`lib/pages/main_page.dart` 的 `PaneActionEntry` 与 import。
- 保留：无。原功能只是两个外链站点（Search by Image Bot、SauceNAO），删掉后仍可在浏览器使用。
- 上游触碰：2 次提交。冲突面最小的一项。
- 状态：已完成。

### 阅读页边距（Page margin）

- 删除：`lib/utils/reader_appearance.dart` 的 `readerPageMargin()`；`lib/pages/reader/images.dart` 的 `initialScale`/`Padding` 边距、边距变化重算缩放块、`_lastPageMargin`、`_unmarginedInitialScales`；`lib/pages/reader/scaffold.dart` 的 `_showPageMargin`、`buildPageMargin()`、`setAppearanceSetting()`、工具栏按钮（`reader-page-margin-toggle`）；`lib/pages/settings/reader.dart` 的两个设置项与 `ReaderPageMarginSetting`（3808 字符）；`lib/foundation/appdata.dart` 的 `readerPageMarginEnabled`、`readerPageMarginPercent` 默认值。
- 保留：`readerBackgroundColor()`；旧数据里残留的两个设置键只是被忽略。
- 测试：删除 `test/reader_page_margin_test.dart`；其中的 `settle()`／`openReader()` 被 `test/reader_book_spread_test.dart`、`test/local_comics_page_test.dart` 与 `integration_test/background_features_test.dart` 复用，已抽到 `test/support/reader_fixture.dart`（comic 标题改为 `Reader fixture`）；`test/support/background_feature_cases.dart` 去掉 `Reader margins` 分组。
- 上游触碰：`images.dart` 81、`scaffold.dart` 67、`settings/reader.dart` 37、`appdata.dart` 95 次提交。合并冲突时本项以本仓库为准。
- 状态：已完成。

### 阅读统计（Reading statistics）

- 待做。计划删除 `lib/foundation/reading_statistics.dart`、`lib/pages/reading_statistics_page.dart`、首页 `statistics` 模块、设置入口、阅读器计时钩子、`reading_statistics.db` 的备份/WebDAV 条目；保留 `recordReadingStatistics` 设置键与旧数据库文件（不迁移、只忽略）。
- 上游触碰：`reading_statistics.dart` 3、`reading_statistics_page.dart` 2、`home_page.dart` 62、`utils/data.dart` 17、`reader.dart`（阅读器）。
- 状态：待做。

### 追更（Follow Updates）

- 待做。计划删除 `lib/foundation/follow_updates.dart`、`lib/pages/follow_updates_page.dart`、首页 `updates` 模块、`init.dart` 启动检查、`headless.dart` 的 `updatesubscribe` 子命令、收藏夹“检查更新”入口与通知、`tool/test_follow_updates_android.sh` 及其工作流断言；保留 `followUpdates*` 设置键与 `local_favorite.db` 的 `has_new_update`/`last_update_time` 等列（上游备份仍可打开）。
- 上游触碰：`follow_updates_page.dart` 14、`follow_updates.dart` 9、`favorites.dart` 40、`home_page.dart` 62。四项里冲突面最大。
- 状态：待做。
