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

## 批次 3 发布基建

- 删除上游发布流水线与配套工具：`.github/workflows/main.yml`（六平台 + 机器人发布）、`.github/workflows/dispatch-release.yml`、`tool/check_release_identity.py`、`tool/test_release_identity.py`、`update_alt_store.py`、`alt_store.json`、`tool/test_alt_store.py`。合并上游时不要让它们回来：这些流程依赖上游的 bot 身份、macOS 证书与 AltStore 源。
- 新增 `.github/workflows/release.yml`：`checks`（analyze + `flutter test --exclude-tags environment` + 版本一致性）→ `android`（用本仓库 keystore 签名，产出 4 个 APK）与 `windows`（便携 ZIP + Inno Setup 安装包）；只有 `v*` 标签触发 `publish`（`SHA256SUMS` + `gh release create`），手动触发只构建不发布。
- Windows 安装包：`windows/build_installer.ps1` 读取 `windows/build.iss` 的占位符（`{{version}}`/`{{root_path}}`）生成 `build/windows/installer.iss` 后调用 `iscc`，输出 `dist/venera-lean-<ver>-windows-x64-setup.exe`；中文化文件 `windows/ChineseSimplified.isl` 已内置（不再在构建时下载），`[Files]` 补上了 `avif_native.dll`。上游的 `windows/build.py` 已删除（它自己重跑 flutter build、改写 build.iss 且 zip 路径不一致）。
- APK 文件名由 `venera-prime-*` 改为 `venera-lean-*`（`android/app/build.gradle`）；应用内更新按 `-<abi>.apk` 后缀选包，命名规则不可随意改。
- 4 个依赖原生库/时序的测试标记 `@Tags(['environment'])`，CI 排除、需在带原生库的环境手工跑 `flutter test --tags environment`。
- `doc/release-policy.md` 与 `test/release_workflow_test.dart` 按本流程重写。
- 状态：已完成。

## 批次 5 平台裁剪

- 维护目标只有 Windows 与 Android。删除 `linux/`、`macos/`、`ios/`、`debian/` 四个平台目录（连同上游在这些平台上的打包定制），以及只服务它们的 `tool/build_appimage.sh`、`pubspec.yaml` 的 `flutter_to_arch` 配置块与 `flutter_to_arch`/`flutter_to_debian` 两个开发依赖。
- 同时删除 Windows ARM64 的打包脚本 `windows/build_arm64.py`、`windows/build_arm64.iss`（该脚本实际打包的是 x64 目录，本身已失效）。
- 保留：`android/`、`windows/`；Dart 里的平台判断（`App.isAndroid`/`App.isWindows`/`Platform.isX`）不动，删它们属于另一类改动。
- 上游合并：上游若再改这些路径，冲突处理恒为「保持删除」。确实需要某个平台时用 `flutter create --platforms=<platform> .` 重新生成模板，但拿不回上游在该平台的定制。
- 状态：已完成。

## 批次 4 自有身份与交互回退

### 应用包名

- Android 的 `namespace`/`applicationId` 改为 `io.github.arteiimis.venera`（集成测试包 `….integrationtest`），Kotlin 源码移到同包路径；Linux app id、iOS/macOS bundle id、集成测试与 adb 脚本、`AGENTS.md` 同步更新。
- Windows 也换成自有身份：`windows/runner/Runner.rc` 的 `CompanyName=Arteiimis`、`ProductName=Venera Lean`、`InternalName`/`OriginalFilename=venera-lean`，`BINARY_NAME=venera-lean`，数据目录因此变成 `%APPDATA%\Arteiimis\Venera Lean`，与上游安装完全分离；安装包用新的 `AppId` 并去掉了上游脚本里删除 `C:\Program Files (x86)\Venera Prime` 的 `[Code]` 块，不会动到已装的上游版本。
- 上游冲突：`android/app/build.gradle`、`AndroidManifest.xml`、`Runner.rc`、`windows/CMakeLists.txt`、`linux/CMakeLists.txt` 合并时以本仓库为准。
- 状态：已完成。

### 本地列表点击直接阅读

- `lib/pages/local_comics_page.dart`：点击漫画直接 `comic.read()`；2.7.0 引入的 `Read`/`View Detail` 选择弹窗（`_openComic`）删除。
- `lib/pages/home_page.dart`：首页「本地」横向条目的点击同样直接进阅读器。
- 查看详情仍在右键菜单（`ComicTile.showMenu` 的 `Details`，打开 `ComicPage`；本地漫画走 `sourceKey == 'local'` 分支），章节列表也在详情页里。
- 测试：`test/local_comics_page_test.dart` 改为「点击即进阅读器」+「右键菜单仍有 Details」；`test/support/reader_fixture.dart` 补 `ReadLaterManager` 初始化，否则右键菜单构建时会抛 `LateInitializationError`（菜单会查阅读稍后）。
- 上游碰撞点：`local_comics_page.dart`（2.7.0 起被大改）、`home_page.dart` 62 次提交。
- 状态：已完成。

### 多图并排自适应

- `lib/pages/reader/images.dart` 的非对开多图页（`readerScreenPicNumberForPortrait/Landscape > 1`）不再把屏幕均分成 N 份、每张图各自 `contain`，改为整屏一起排版：`lib/utils/reader_spread_geometry.dart` 的 `readerRowRects()` 在"每张图保持比例、总宽不超过屏幕、单张不超过屏幕"的约束下最大化**最小显示面积**（对面积做水位法二分），于是竖屏图可以吃满高度、横屏图吃掉剩余宽度，各图尽量大、高度允许不同，整组铺满宽度（全部到顶时则自然居中留边），不溢出也不裁切；竖排模式对偶处理（由共宽改为共高）。
- 翻页不再闪一下再适应：`_resolveImageSize()` 在相邻页仍处于屏幕外时就通过 ImageStream 解析宽高，翻页后的第一帧即为最终布局。
- `readerSpreadRects()`（双页对开）保持原样：对开书页共享一个高度。
- 测试：`test/reader_spread_geometry_test.dart` 覆盖竖屏+横屏、等比、竖排与 36 组比例的不变量；`test/reader_multi_image_layout_test.dart` 断言竖屏吃满高度、横屏占剩余宽度、整组铺满视口，以及翻到下一页的第一帧已是最终几何（预解析生效）。
- 上游碰撞点：`images.dart` 81 次提交，合并时保留本实现。
- 状态：已完成。

### 阅读器空格键切换自动翻页

- `lib/pages/reader/reader.dart`：`onKeyEvent` 只拦截 `KeyDownEvent` 的空格，调用 `toggleAutoPageTurning()`；屏幕中央淡入 900ms 的暂停/播放圆形图标（`AnimatedOpacity`，key `auto-page-turn-indicator`），工具栏按钮改走同一入口（`lib/pages/reader/scaffold.dart`）。
- 顺带修正：自动翻页走到最后一页自动停止时把 `autoPageTurningTimer` 置空并刷新，避免图标与工具栏仍显示「运行中」。
- 测试：新增 `test/reader_auto_page_turn_test.dart`（空格开/关、图标状态、900ms 后淡出）。
- 上游碰撞点：`reader.dart`、`scaffold.dart` 都是上游高频文件（scaffold 67 次提交），合并时保留本改动。
- 状态：已完成。

### 开发版窗口与正式版并存

- `windows/runner/main.cpp`：Debug 构建的窗口标题改为 `Venera Lean (Dev)`（`_DEBUG` 由 `windows/CMakeLists.txt` 的 `apply_standard_settings` 定义）；正式构建保持 `Venera Lean` 不得改动。
- 原因：`win32_window.cpp` 的 `Win32Window::Create` 按「窗口类名（`FLUTTER_RUNNER_WIN32_WINDOW`）+ 标题」调用 `FindWindow`，命中就把已有窗口提到前台并让新进程 `EXIT_FAILURE`。标题相同意味着正式版开着时 `flutter run -d windows` 只激活正式版窗口后直接退出。
- 效果：正式版与开发版可同时开窗；两个开发版之间仍各自单实例（第二个仍以退出码 1 退出）。应用内标题栏本就有 `kDebugMode` 下的 Debug 按钮作为第二个区分标志。
- 数据目录没有隔离：两者仍共用 `%APPDATA%\Arteiimis\Venera Lean`（`Runner.rc` 的 CompanyName/ProductName 未改）。同时运行只适合看界面；开发版若改了数据库结构或数据迁移，正式版不一定能读回。
- 上游碰撞点：`main.cpp` 上游极少改动，合并时保留本实现。
- 状态：已完成。

## 批次 6 磁盘繁忙时的卡顿与闪退

背景：系统磁盘被其它程序占满时，界面会明显卡顿，Windows 上偶尔直接退出（无报错、退出码 0）。原因是 UI isolate 上的同步 sqlite 调用，加上默认的回滚日志(synchronous=FULL)在每次提交都会 fsync 日志与数据库文件——磁盘一慢，每一次历史/收藏/缓存写入都会阻塞帧；Windows runner 的看门狗在 UI 线程心跳停 5 秒时 `std::exit(0)`，于是表现为「闪退」。

- `lib/foundation/db.dart`：新增 `openAppDatabase()`，所有应用数据库（history、local_favorite、read_later、cookie、cache、local）改为以 `journal_mode=WAL` + `synchronous=NORMAL` + `busy_timeout=5000` 打开。WAL 把提交留在日志里，不再每次 fsync；进程崩溃仍然安全（掉电可能丢最后几个事务）。上游合并时保留：上游仍是默认回滚日志。
- `lib/foundation/cache_manager.dart`：缓存命中不再每次 `UPDATE last_access`，改为内存批量（32 条或清理前）一次事务写回；清理时若候选在此期间被读过则跳过删除。
- `lib/foundation/db.dart`：`verifyAppDatabase()` 用 `PRAGMA quick_check` 加上「文件大小:mtime」标记，只在数据库文件变化后做一次结构校验（原来是每次启动全量 `integrity_check`，磁盘慢时会拖住启动）。
- `lib/utils/data.dart`：恢复备份时，先把被替换数据库的 `-wal`/`-shm` 清掉再换文件（否则旧日志回放到新数据会损坏数据库），清理失败只告警。
- `windows/runner/flutter_window.cpp`：看门狗超时 5s -> 30s，避免磁盘抖动导致静默退出。
- 测试：`test/app_database_test.dart`（WAL/同步级别/busy_timeout、校验标记、损坏文件）；`test/data_backup_test.dart` 的 legacy 夹具改为先 checkpoint 再读原始数据库文件。
- 已知副作用：WAL 期间 sqlite 持有的文件句柄不共享删除，Windows 上「测试结束删临时目录」这类操作若还有连接存活会报 errno 32（仅影响少数本地测试，Linux CI 不受影响）；数据库目录里会多出 `-wal`/`-shm`/`.verified` 文件。
- 状态：已完成。

## 批次 7 来源与占用移入本地卡片

背景：上游把本地漫画的来源与磁盘占用作为独立一窄行挂在卡片下方（`SliverGridComics.itemWrapper` 包一层 `Column`），既占网格高度又把封面压小。

- `lib/components/comic.dart`：`ComicTile` 新增可选 `footer`（懒构建 `Widget Function()?`），只在详细模式渲染在描述区底部右侧（卡片右下角）；简报模式不渲染也不调用构建器。`SliverGridComics`/`_SliverGridComics` 的 `itemWrapper` 换成 `footerBuilder`（上游 2.7.0 只为这个占用行加的包装钩子，现已无其它使用者），构建器只在详细模式调用，简报模式不会触发目录大小遍历。
- `lib/pages/local_comics_page.dart`：`FutureBuilder<int>` 直接作为 `footerBuilder` 的返回值，不再包 `Column`/`Expanded`，卡片恢复满高；`_size()` 与 `_sizes` 缓存不变。
- 测试：`test/local_comics_page_test.dart` 断言来源/占用文本位于 `ComicTile` 内。
- 上游碰撞点：`comic.dart` 77 次提交（公共组件，只新增可选参数）、`local_comics_page.dart` 32 次。合并时保留本实现，不要让 `itemWrapper` 回来。
- 状态：已完成。

## 批次 8 收藏夹搜索与搜索性能

背景：网络收藏夹没有任何搜索入口，源契约里也没有服务端搜索接口；本地收藏与本地漫画的实时搜索每敲一个字符都全量重算（收藏页逐条做简繁转换与 tag 翻译，本地库重跑 SQL 并解码整行），读过滤器还在每次 `build` 里逐条查历史。

- 新增收藏夹服务端搜索：`FavoriteData.search`/`searchNext`（`lib/foundation/comic_source/favorites.dart`）、`lib/foundation/comic_source/parser.dart` 解析 `favorites.search`/`favorites.searchNext`（复用登录过期重试），`doc/comic_source.md` 补契约。`lib/pages/favorites/network_favorites_search.dart` 是搜索页：只调源的 `search`/`searchNext`，不做客户端逐页扫描；`network_favorites_page.dart` 仅在源实现了搜索时于 appbar 显示入口（含加载失败页）。`search` 优先于 `searchNext`，与 `loadComics`/`loadNext` 一致。
- 新增 `lib/utils/comic_search.dart`：收藏搜索索引（预计算小写字段/tag 值，简繁转换与大小写判断每查询一次）与本地库索引（对齐原 SQL `LIKE` 语义）。本地收藏页、本地漫画页改为索引/内存过滤；本地漫画的 `_sizes` 缓存不再随每次按键清空。
- 读过滤器：`HistoryManager.readCompletion()` 用一条轻查询生成快照，`local_favorites_page.dart` 只在收藏列表/过滤器/历史变化时重算；历史 key 改用收藏的 `type`（此前用 `sourceKey.hashCode`，本地类型收藏永远匹配不到历史）。
- 修 `lib/utils/opencc.dart` 的 CRLF 解析：Windows 检出（`core.autocrlf=true`）时每行多一个 `\r` 被整行跳过，Windows 构建的简繁互搜此前完全失效，Linux 正常。
- 上游碰撞点：`local_favorites_page.dart` 50、`local_comics_page.dart` 32、`parser.dart` 37、`history.dart` 29、`comic_source/favorites.dart` 5、`network_favorites_page.dart` 16、`opencc.dart` 3、`translation.json` 157（只加键）、`doc/comic_source.md` 8。合并时保留本实现。
- 测试：`test/comic_search_test.dart`（含与旧匹配器的 parity）、`test/history_read_completion_test.dart`、`test/network_favorite_search_test.dart`（搜索调用、空结果、仅 `searchNext`、入口可见性）。
- 源侧实现不在本仓库：本机 `comic_source/ehentai.js` 已加 `favorites.searchNext`（`favorites.php?f_search=` + `favcat`，下一页走站点 `next` 游标），版本同步到 1.2.1，供本地验证（原文件备份为 `ehentai.js.bak`）。已向 `venera-app/venera-configs` 提 PR #360：ehentai 源实现 + `_template_.js` 契约说明 + `index.json` 版本 1.1.8 → 1.2.1。
- 状态：应用侧已完成；等源侧与上游合并策略确定。
## 批次 9 工具链与依赖（Flutter 3.50.1）

背景：升级 Flutter 与两个热点依赖，并在 Windows 上用自建基线脚本量化渲染路径。

- Flutter 3.41.4 → 3.50.1：`.fvmrc`、`pubspec.yaml` 的 `flutter:` 精确约束、`.github/workflows/release.yml` 三处 `flutter-version` 同步。上游仍为 3.41.4，同步上游时 `.fvmrc`、`pubspec.yaml`、`release.yml` 以本仓库为准。
- 分析门禁：3.50 起 `package:flutter/material.dart` 被标记废弃（建议 `package:material_ui/material_ui.dart`），全仓约 100 个文件；import 迁移未做，CI 的 `flutter analyze` 改为 `--no-fatal-infos`，保留可见的 info。迁移落地后改回原样。
- Windows 关闭 Impeller（`windows/runner/main.cpp`）：3.47 起桌面默认 Impeller，本机量测首帧光栅 290 ms（Skia 30 ms）、列表滚动光栅 p50 1043 µs（Skia 657 µs）；关闭后 3.50.1 与 3.41.4 持平（首帧 21 ms、列表 629 µs）。改开关属于对上游行为的改写，上游合并时保留。
- `packages/rhttp/pubspec.yaml`：`flutter_rust_bridge` 由 `^2.11.1` 改为精确 `2.11.1`，与 `frb_generated.dart` 的 `codegenVersion` 及 `rust/Cargo.toml` 的 `=2.11.1` 对齐，避免升级后 pub 解析抬高 Dart 侧导致初始化失败。
- `flutter_qjs` 改为 `github.com/Arteiimis/flutter_qjs` 的 `a8ad8ec`：内置 quickjs-ng 从 0.8.0（2024-02-14）升到 0.18.0，`cxx/ffi.cpp` 适配新 API（`JSInterruptHandler` 收到 `JSContext*`、`JS_IsArray`/`JS_IsError` 去掉 ctx），`cxx/quickjs.cmake` 跟随上游文件布局（去掉 libbf、加 dtoa）。上游 pin 的是 venera-app 的旧提交，合并时保留本引用。
- `archive` 4.0.7 → 4.7.1：解压/写入路径的量化收益来自上游 changelog（deflate 约 2.5 倍、逐条读 zip 约 1.5 倍）。
- 新增 Windows 帧基线：`integration_test/performance_frames_test.dart` + `tool/test_performance_windows.ps1`（profile 构建直接运行，采样写 `.dart_tool/performance-audit/`；`flutter drive` 无法稳定 attach Windows profile 进程，故不走 drive）。
- Android 工具链跟随 3.50 的硬性下限（Gradle ≥ 9.3.1、AGP ≥ 9.1.1、KGP ≥ 2.4.10）：`android/gradle/wrapper/gradle-wrapper.properties` 8.13 → 9.5.0，`android/settings.gradle` → AGP 9.3.1 / KGP 2.4.20，`android/gradle.properties` 按 Flutter 模板固定 `android.newDsl=false`、`android.builtInKotlin=false` 并移除 AGP 9 已删除的 Jetifier 等开关。Gradle 9 删除 `Project.buildDir` 与 `Project.exec`，根脚本改用 `layout.buildDirectory`，`packages/rhttp/cargokit/gradle/plugin.gradle` 改为注入 `ExecOperations`。KGP 2.4 移除 `kotlinOptions`，`android/app/build.gradle` 改用 `kotlin.compilerOptions`。AGP 9 把 AAR metadata 检查变成硬失败而 `zip_flutter` 仍声明 compileSdk 33，根脚本在 `afterEvaluate` 把全部 Android 模块抬到 36（须在强制求值 `:app` 之前注册）。`packages/rhttp` 的 compileSdk 33 → 36。`flutter_inappwebview` 的 Android 模块仍用 `proguard-android.txt`（AGP 9 直接报错），pub.dev 最新 6.1.5 比现有 fork 更旧，故镜像到 `Arteiimis/flutter_inappwebview` 分支 `agp9-proguard`（49a0c88，只改这一处文件名）。`packages/flutter_saf`（AGP 8.1.0）与 `packages/rhttp`（AGP 7.3.0）buildscript 里钉的旧 AGP 与 9.3.1 同处 classpath，导致 lint 抛 `NoSuchMethodError: JavaDocParser.parseDataItem`，两处 buildscript 已删。CI Android job 的 JDK 17 → 21：AGP 9.3 的 lint 调用 `List.removeLast()`（Java 21+）。
- 本机验证注意：KGP 2.4 的增量缓存要求源码与工程同盘（本机工程在 F:、`PUB_CACHE` 在 D: 时会抛 “different roots”），本地跑 Android 构建需让 `PUB_CACHE` 与工程同盘。
- 状态：已完成；material_ui 迁移见批次 12。

## 批次 10 本地卡片占用统计与封面解码

背景：本地卡片右下角的「来源 · 占用」每次打开页面都要重新遍历目录（缓存挂在页面 State 上，页面是每次新开的路由），而且遍历在 UI isolate 上逐文件 `await File.length()`——本机 193 本 / 9.9 万个文件的库，首屏 10 本就要占 UI 线程 140～530 ms；封面按原尺寸解码，重启后首次打开要和遍历一起解码几十张封面，表现为「卡一下」。

- `lib/foundation/local.dart`：`comics` 表新增可空的 `size_bytes`/`size_checked_at`（启动时 `ALTER TABLE` 迁移，两处 `CREATE TABLE` 同步），`LocalComic` 新增 `sizeBytes`/`sizeCheckedAt`。`add()` 的 upsert 一律把两列置 NULL：所有 app 内写入（下载章节、导入、刷新库）都走它，等于自动失效，不需要额外钩子。新增 `LocalManager.setSize()`（不 notify，避免每个卡片触发整页重建）、`measureSize()`（isolate 测量并写回）、`hasFreshSize()` 与 `sizeCacheTtl = 1 天`（兜底资源管理器里的外部改动）。
- `lib/utils/io.dart`：新增 `directorySizeIsolate()`，`Isolate.run` + `listSync/lengthSync`，不跟链接；根目录缺失仍抛错（卡片显示 Unavailable），子目录不可读或文件中途消失只跳过。实测 10 本大书（19k 文件）：UI isolate 上 531 ms → isolate 1.8 s 且 UI 线程为 0。
- `lib/pages/local_comics_page.dart`：footer 优先同步渲染数据库里的新鲜值；缺失或过期时用 `FutureBuilder.initialData` 先显示旧值再在 isolate 重测（stale-while-revalidate）；`update()` 不再整体清空 `_sizes`，只丢掉数据库里已无值的条目。
- `lib/foundation/image_provider/base_image_provider.dart`、`local_comic_image.dart`：像素预算从静态改为可覆盖的 `maxDecodedPixel`；`LocalComicImageProvider` 开 `enableResize` 并把预算设为 800×1200（封面只在卡片尺寸显示，此前 3 MB 的 cover.jpg 会解码成 32 MB 纹理并挤占图片缓存）。`ReaderImageProvider` 等仍用 2560×1440。
- 测试：新增 `test/local_size_cache_test.dart`（isolate 统计、持久化、TTL、写入失效、目录消失报错）、`test/local_cover_size_test.dart`（真实加载管线里拿到的目标尺寸）；`test/local_migration_test.dart` 加上一版库的迁移用例；`test/local_comics_page_test.dart` 断言占用等于真实目录总量、已写入数据库，并在重开页面后同步出现。
- 上游碰撞点：`local.dart`（65 次上游提交；列、`fromRow`、`add()` 的 upsert 三处）、`local_comics_page.dart`（32 次）、`image_provider/base_image_provider.dart`、`image_provider/local_comic_image.dart`。合并时保留本实现：上游若把 `add()` 的 upsert 改回去，缓存不再失效，会显示过期的占用。
- 状态：已完成。未跑 Windows 帧基线：`tool/test_performance_windows.ps1` 只测启动首帧和生成像素的列表滚动，不经过本地页和图片 provider。

## 批次 11 本机测试基线（Windows 测试宿主）

背景：`flutter test --exclude-tags environment` 在 Windows 本机长期有 17 个稳定失败，Linux CI 全绿，因此没人敢把它们当成回归信号。逐项追下来只有两类原因：测试写在 Windows 上不成立的假设，以及被测代码里 20 ms 轮询式的串行化。

- `lib/foundation/appdata.dart`：`saveData`/`writeImplicitData` 的 `while (_isSavingData) await Future.delayed(20 ms)` 换成写串行链（`_writeChain`）。链式 future 在 `Zone.root` 内创建，并且第一次写入时惰性起头：否则在 widget 测试的 fake-async zone 里建出来的 future 会在该 zone 停止泵送后再也不完成，后续写入与 `flushSearchProgress` 一起卡死。`flushSearchProgress` 除了自己的保存，还等 `_pendingSave`，因此“后台已经在写、测试却开始删临时目录”的竞态消失（`test/search_history_test.dart` 的 errno 145）。
- `lib/pages/webview.dart`：Windows 分支的判断从 `App.isWindows`（真实 `Platform.isWindows`）改为 `defaultTargetPlatform == TargetPlatform.windows`，与同函数里的 Android 分支一致；测试用 `debugDefaultTargetPlatformOverride` 就能在任意宿主上走这条分支（`test/webview_platform_test.dart` 12 例）。
- `test/webview_platform_test.dart`：fake `InAppWebViewPlatform` 补 `createPlatformWebViewEnvironmentStatic`（`WebViewEnvironment.create` 走的是 static 工厂，不是带 params 的那个），并给 `App.dataPath` 指向临时目录——Windows 分支会拿它拼 WebView2 用户数据目录。
- `test/reader_scrubbing_test.dart`：页面 PNG 换成引擎真能解码的 1×1 PNG。原来的 base64 只有 GDI+ 能解，Flutter 解码报 `Codec failed to produce an image`，于是图片读取永远停在“文件句柄还开着”的状态，Windows 删临时目录报 errno 32。
- `test/reader_image_reload_test.dart`：去掉 `@Tags(['environment'])`。三处修正——`HttpOverrides.global = null`（flutter_test 默认把所有请求变成 400，环回服务器根本收不到）、`AppDio.adapterOverride`（rhttp 原生库在测试进程里加载不了，见下条）、teardown 先 `CacheManager().close()` 再删目录（`close()` 会等排队中的缓存操作，所以要边等边 pump）。
- `lib/network/app_dio.dart`：新增 `@visibleForTesting static HttpClientAdapter Function()? adapterOverride`，构造时优先用它而不是硬编码的 `RHttpAdapter()`；测试注入 `IOHttpClientAdapter`。
- 新增 `test/support/temp_dir.dart`：`deleteTempDirectory(tester, dir)` 与 `deleteEventually(dir)`，对 errno 32/145 重试最多 10 次（每次跑真实时间再 pump），`test/home_layout_test.dart`、`test/favorites_batch_move_test.dart`、`test/reader_scrubbing_test.dart`、`test/reader_image_reload_test.dart` 改用它。
- 上游碰撞点：`appdata.dart` 95 次提交、`webview.dart`、`app_dio.dart` 都是上游常改文件；合并时本仓库的串行写链与 `adapterOverride` 优先。
- 测试：`fvm flutter test --exclude-tags environment` 在本机 Windows 上 380 通过、20 跳过、0 失败（此前 366/20/17）。
- 状态：已完成。

## 批次 12 Flutter 3.50 弃用清理（material_ui / onReorderItem）

背景：批次 9 把分析门禁放宽成 `--no-fatal-infos`，因为 3.50 把设计库拆成 pub 包后 `package:flutter/material.dart` 整体被标废弃（98 个文件），另有 `ReorderableListView.onReorder`（6 处）与两个本地化委托。项目已决定与上游解耦，这里把三类 info 全部清掉，门禁收回原样。

- 依赖迁移：新增 `material_ui: ^1.11.1`；`flex_seed_scheme` 4.0.1 → 5.0.1、`dynamic_color` 1.8.1 → 2.1.0（两者都改为依赖 material_ui，`SeedColorScheme.fromSeeds` 与 `DynamicColorBuilder` 因此直接返回 material_ui 的 `ColorScheme`，主色方案不用手写桥接）。`dart fix --apply --code=migrate_design_widgets` 重写 98 个文件的 import。
- `lib/main.dart`：`localizationsDelegates` 改用 material_ui 的 `GlobalMaterialLocalizations.delegates`（它已包含 cupertino/widgets 两个委托），并去掉 `flutter_localizations` 的 import——两个包各有一份同名类会冲突。`MaterialApp.builder` 最外层加 `MaterialUiCompatibilityBridge`，把 material_ui 的 `ThemeData` 映射成 `flutter/material.dart` 侧的 legacy `Theme`，给还没迁移的依赖（photo_view、mobile_scanner、flutter_inappwebview 等）用；该类自身带 `@Deprecated`（官方定位是过渡工具），所以那一行加了 `// ignore: deprecated_member_use` 并写了原因。依赖都迁移后整块删掉。
- `onReorder` → `onReorderItem`：`comic_source_page.dart`（源列表、源库列表）、`favorites/favorite_actions.dart`、`local_comics_page.dart`、`settings/home_layout_page.dart`。新回调的 `newIndex` 已按“移除后”调整，故原有的 `if (newIndex > oldIndex) newIndex--;` 一律删除，否则会多减一位；`test/home_layout_test.dart` 直接调回调模拟拖拽，断言不变、参数改为 `(0, 2)`。
- `lib/foundation/app_update.dart`：`_deletePartial` 重试删除 `.part` 文件（最多 1 秒）并吞掉失败。取消下载时 dio 的 sink 还握着句柄，Windows 删文件报 errno 5，原来会在 `finally` 里盖掉真正的 `DioException`，也导致 `test/app_update_test.dart` 并发跑时偶发失败。
- `.github/workflows/release.yml`：`flutter analyze --no-fatal-infos` 改回 `flutter analyze`。
- 上游碰撞点：98 个文件的 import 行、`main.dart`、四个重排页面。上游仍在 3.41.4 且全量 import `flutter/material.dart`，合并时 import 一律以本仓库为准。
- 测试：`fvm flutter analyze` 无任何 issue；`fvm flutter test --exclude-tags environment` 本机 380 通过、20 跳过、0 失败。
- 状态：已完成。

## 批次 13 Windows 3.50 引擎崩溃的临时修复（ANGLE D3D11 多线程保护）

背景：升级 Flutter 3.50.1 后，Windows 版在长列表（本地页 188 本）快速滚动时**直接闪退、无 Dart 异常**。事件查看器固定指向 `nvwgf2umx.dll`（NVIDIA D3D11 驱动）`0xc0000005`，偏移稳定在 `+0x612f73`；崩溃线程是驱动自己起的 worker，另一线程停在 `ID3D11DeviceContext::Flush`。

- 定位：二分确认与业务代码无关——同一份代码用 3.41.4 引擎（`e65d4ac`）不崩，只有 3.50.1 崩；`master`（含本地占用缓存批次）与只含 material_ui 批次的分支都会崩。上游对应 issue：flutter/flutter#196846（NVIDIA 上 3.50.0 崩、3.47.9 正常）与 #196618（3.50 的 ANGLE 改版后 `eglSwapBuffers` 不再排除 IO 线程的 GL 调用，两个线程同时用同一个 D3D11 immediate context）。修复 PR #196897 / CP #196991（给 ANGLE 的设备开 `ID3D10Multithread::SetMultithreadProtected(TRUE)`）在 2026-11-19 合入，而 3.50.1 的引擎构建于 2026-11-18，故不含此修复；当时最新的 beta 3.51.0-0.2.pre 同样早于该修复。
- 做法：新增 `windows/runner/d3d11_multithread_patch.{h,cpp}`，在 `main.cpp` 建窗口前调用 `venera::InstallD3D11MultithreadPatch()`。实现方式是把 `flutter_windows.dll` 导入表里的 `kernel32!GetProcAddress` 换成自己的包装，拦到 `D3D11CreateDevice` / `D3D11CreateDeviceAndSwapChain` 后返回包装函数：调用真实创建函数，成功后 `QueryInterface(ID3D10Multithread)` 并 `SetMultithreadProtected(TRUE)`。引擎（ANGLE）是运行时解析 d3d11 入口的，所以能拦到它创建的设备。
- 坑（已踩过一次）：`GetProcAddress` 也接受**序号**，此时第二个参数是小整数而非字符串指针；包装里必须先判断 `(reinterpret_cast<ULONG_PTR>(name) >> 16) == 0` 就直接放行，否则启动即 `0xc0000409`（ucrtbase 快速失败）。
- 验证：补丁前，同一份构建用脚本连续甩动本地页 20 次必崩（两次复现、均生成 dump）；补丁后连续 120 次甩动无崩溃、无新 dump，用户手工验证正常。`fvm flutter analyze` 与测试套件不受影响（纯 Windows runner 代码）。
- 移除条件：升级到包含 #196897（或上游正式发布的 3.50.2+）后，删除这两个文件、`main.cpp` 中的调用与 `CMakeLists.txt` 里的源文件条目。上游修复做的事与本补丁相同，重复启用无副作用，只是多余。
- 上游碰撞点：`windows/runner/main.cpp` 已有本仓库自己的改动（关闭 Impeller），合并上游时保留两处。
- 状态：已完成；待 Flutter 升级后移除。
