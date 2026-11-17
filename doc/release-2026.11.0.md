# Venera Lean 2026.11.0

首个独立发行版本，基于 venera-app/venera-prime 2.8.1。自此本仓库独立维护、独立发版。

## 本次更新

- **独立版本线**：版本号改为 CalVer（`年.月.序号`），构建号从 30001 起；应用内更新只检查本仓库（Arteiimis/venera-lean）的 Release，只接受本仓库 `releases/download/` 下的资产。
- **自有应用标识**：Android 包名为 `io.github.arteiimis.venera`，与 Venera Prime 的包名不同，可同时安装、互不覆盖；Windows 使用独立数据目录 `%APPDATA%\Arteiimis\Venera Lean`，可执行文件为 `venera-lean.exe`。
- **功能精简**：移除阅读统计、追更、百宝箱与阅读页边距设置。
- **备份与上游分离**：备份格式升级为 2（带 `product: venera-lean` 标记），WebDAV 文件名使用 `lean-` 前缀，可与上游备份共存于同一目录；设置 → 应用中提供一次性「从 Venera Prime 迁移」入口。
- **阅读体验**：本地列表与首页「本地」块点击直接进入阅读（详情保留在右键菜单）；阅读器按空格切换自动翻页，屏幕中央显示暂停/播放状态图标；多图并排时按各自比例自适应铺满屏幕，并在翻页前预解析相邻页尺寸，避免翻页后画面再跳一次。
- **磁盘繁忙时不再卡顿**：数据库改用 WAL 提交、缓存访问记录批量写回、启动只校验一次数据库结构，Windows 端也不会因为几秒的卡顿被看门狗直接退出。
- **发布基建**：CI 覆盖 Windows 与 Android 两平台，产出 4 个签名 APK、Windows 便携 ZIP 与 `SHA256SUMS`，推送 `v<版本>` 标签即自动发布。

## 升级与迁移

- **从 Venera Prime 迁移**：先在上游应用中导出 `.venera` 备份，再在本版本「设置 → 应用 → 从 Venera Prime 迁移」导入一次。导入后阅读统计与追更不会恢复（对应功能已移除），此后本版本的备份只与本版本同步，不再与上游备份混用。
- **Android**：包名与上游不同，可与 Venera Prime 并存；从本版本再升级时保持同签名即可覆盖安装。
- **Windows**：便携包解压即用；首次启动会新建独立数据目录，不会读写 `%APPDATA%\com.github.wgh136\Venera Prime`。
- 首次启动会显示项目说明，需点击「我已了解，开始使用」后才能进入。

## 请更新后验证并反馈

- 本地漫画的浏览与阅读、左右翻页、双页对开、连续模式。
- 阅读器空格键切换自动翻页及中央状态图标。
- 收藏、历史、阅读稍后、漫画源登录状态。
- 备份导出/恢复、WebDAV 同步与「从 Venera Prime 迁移」的导入结果。
- 反馈请附版本号、系统与设备、漫画源、复现步骤与脱敏后的日志或录屏。

## 验证范围

- 已执行：`fvm flutter analyze` 无问题；Linux CI 全量单元/组件测试通过（排除 4 项依赖原生库或精确时序的 `environment` 用例）；Windows 本地 debug/release 构建与手工冒烟（WAL 落盘、e-hentai 图片加载正常）；CI 产物经 `aapt2 dump badging` 核对包名、版本号与应用名，经 `apksigner` 核对签名证书指纹与本仓库 keystore 一致；Windows ZIP 内容核对。
- 未执行：真机 Android 的安装与更新链路、真实 WebDAV 服务器的端到端同步、Windows 安装包（Inno Setup）验证。
- Windows 便携包未做代码签名，首次运行时 SmartScreen 可能提示「未知发布者」。

## 已知限制

- 多图并排的比例来自图片解码结果：在本进程内首次显示某一页时，仍可能有一帧占位布局（之后立即修正）。
- 上游「项目说明」中的交流群链接属于上游社区，本版本只保留只读入口，不再声称本分支有自己的群。
