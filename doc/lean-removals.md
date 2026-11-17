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

- 删除：`lib/foundation/reading_statistics.dart`、`lib/pages/reading_statistics_page.dart`（整文件）；`lib/foundation/app.dart` 的 `readingStatistics` 实例与 init/close；首页 `statistics` 模块与预览组件（含只给它用的 `_PreviewMetric`）；`home_layout.dart` 的模块项；设置 → 应用里的入口；`lib/pages/reader/reader.dart` 的会话计时（`_readingSessionStarted`、`_commitReadingSession`、`WidgetsBindingObserver` 及 add/removeObserver——此处只服务统计）；`lib/utils/data.dart` 中 `reading_statistics.db` 的导出/校验/回滚/关闭重开；`appdata.dart` 的 `recordReadingStatistics`（设备级同步键 + 默认值）。
- 保留：用户磁盘上已有的 `reading_statistics.db` 不删（不再读写）；旧备份里多出的该文件在导入时被忽略。
- 测试：删除 `test/reading_statistics_test.dart`；`test/data_backup_test.dart` 与 `test/support/data_sync_cases.dart` 去掉统计用例；阅读器测试里为关闭统计写的 `recordReadingStatistics` 置位一并删除。
- 上游触碰：`reading_statistics.dart` 3、`reading_statistics_page.dart` 2、`home_page.dart` 62、`utils/data.dart` 17。
- 状态：已完成。

### 追更（Follow Updates）

- 删除：`lib/foundation/follow_updates.dart`、`lib/pages/follow_updates_page.dart`（整文件，含 `FollowUpdatesService`/`getUpdatedComicsAsJson`）；首页 `updates` 模块；`home_layout.dart` 的模块项；`init.dart` 的启动检查与 `_followUpdatesRequested`；`headless.dart` 的 `updatesubscribe` 子命令；`components/background_tasks.dart` 的 “Follow Updates:” 标题映射；`favorites.dart` 的全部追更簿记（`FavoriteItemWithUpdateInfo`、`prepareTableForFollowUpdates`、`updateUpdateTime`、`recordFailedUpdateAttempt`、`updateCheckTime`、`countUpdates`、`getUpdates`、`getComicsWithUpdatesInfo`、`markAsRead`、`onRead` 里的 `has_new_update` 清零、`addComic` 的 `updateTime` 参数）；`comic_details_page` 中把 `findUpdateTime()` 传进收藏面板的链路（`actions.dart`、`favorite.dart` 三个组件的 `updateTime` 字段）；`comic_source/models.dart` 的 `findUpdateTime()` 与只给它用的 `_validateUpdateTime()`；`appdata.dart` 的 4 个 `followUpdates*` 默认值；`tool/test_follow_updates_android.sh` 与 `test/release_workflow_test.dart` 对该脚本的断言。
- 保留：`local_favorite.db` 的 `has_new_update`/`last_update_time`/`last_check_time`/`last_attempt_time`/`last_update_chapters` 列与旧 `followUpdates*` 设置键——不删表、不删列，上游备份仍能原样导入；不再有任何代码读写它们。
- 测试：删除 `test/follow_updates_test.dart`、`test/support/follow_updates_cases.dart`、`integration_test/follow_updates_test.dart`；`integration_test/release_regression_test.dart` 去掉 Follow updates 分组与相关 import。
- 上游触碰：`follow_updates_page.dart` 14、`follow_updates.dart` 9、`favorites.dart` 40、`home_page.dart` 62。四项里冲突面最大。
- 状态：已完成。

## 批次 2 备份与上游分离

- 导出：`manifest.json` 写 `{"format": 2, "product": "venera-lean", "files": [...]}`（常量 `backupManifestFormat` / `backupManifestProduct`，`lib/utils/data.dart`）。
- 导入：`importAppData` 默认只接受本仓库 format 2。无 manifest 或 `format: 1` 的上游备份抛 `UpstreamBackupException`，UI 提示改用迁移入口；未知 format（如 99）即便走迁移入口也拒绝。
- 迁移入口：设置 → 应用里唯一一项「从 Venera Prime 迁移」，以 `allowUpstream: true` 导入一次上游备份；导入后 `_dropRemovedFeatureState()` 清掉已删功能的设置键（`followUpdates*`、`recordReadingStatistics`、`readerPageMargin*`）并把 `homeLayout` 归一化到现存模块。
- WebDAV：文件名改为 `lean-<day>-<version>-<micros>-<uuid>.venera`；远端列举、版本推进、保留策略与"最新备份"选择全部只认 `isOwnBackupName()`，与 Prime 备份共用同一目录时互不干扰。
- 测试：`test/data_backup_test.dart` 的构造备份改为携带本仓库 manifest，无 manifest 的用例改走 `allowUpstream: true`，并新增"上游备份走普通导入被拒"断言；`test/data_sync_backup_policy_test.dart` 全部改用 `lean-` 前缀；`test/home_layout_test.dart` 把已删除的 `statistics` 模块 id 换成 `history`。
- 状态：已完成。
