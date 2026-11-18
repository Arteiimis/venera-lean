# venera-lean 项目约定

本仓库是 [venera-app/venera-prime](https://github.com/venera-app/venera-prime) 的独立精简发行版：git 历史完整镜像自上游，`master` 即产品线，只维护 Windows 与 Android。`git diff upstream-master` 始终等于本仓库相对上游的全部改动。

## 分支与上游同步

- 上游只同步 `master`、不带 tag：`git fetch upstream master:upstream-master`。带 tag 会和上游的 `v2.x` 撞名。
- 合入上游用 `git merge upstream-master`；master 上不要 rebase，历史必须保持可与上游合并。
- 删除功能或改写上游行为，必须在同一提交里记入 [doc/lean-removals.md](doc/lean-removals.md)（写法约定、批次记录、上游高频改动文件都在那里）。合并冲突涉及已删除的代码时一律保留删除，不要顺手恢复。
- `linux/`、`macos/`、`ios/`、`debian/` 是刻意删除的：不要从上游恢复，也不要用 `flutter create --platforms` 重新生成。

## 工具链与测试

- 一律 `fvm flutter` / `fvm dart`（`.fvmrc` 固定 3.41.4，与 CI 一致）。系统 Flutter 3.50 会改写 `pubspec.lock` 和 `analysis_options.yaml`。
- 跑数据库相关测试前把 `D:\tools\sqlite3` 加进 `PATH`（提供 `sqlite3.dll`），否则全部 DB 测试报 `Failed to load dynamic library`。
- `fvm dart format` 只格式化本次改到的文件：全量会重排约 60 个无关文件。
- 用 rg 挑测试文件时排除 `test/support/`（那是 fixture 不是测试），否则 `flutter test` 报 loading 失败。
- 本机 Windows 有一批既有的环境失败。判定某个失败为“既有”之前，必须 `git stash` 后在 HEAD 上复跑对比——此前有过把真实回归误判为既有失败的先例。
- CI 只跑 `flutter test --exclude-tags environment`；`@Tags(['environment'])` 的文件需要在能构建原生库的机器上手工跑，范围见发布规范。

## 身份与数据

- Android：`applicationId`/`namespace` = `io.github.arteiimis.venera`，集成测试变体 `io.github.arteiimis.venera.integrationtest`。
- Windows 数据目录 = `%APPDATA%\Arteiimis\Venera Lean`，由 `windows/runner/Runner.rc` 的 CompanyName/ProductName 决定。改动这两个值等于让老用户的数据目录凭空消失。
- 备份 manifest 为 `{format: 2, product: "venera-lean"}`；WebDAV 只认 `lean-` 前缀，且必须用自己的远端目录——上游把目录里所有 `.venera` 计入 10 个保留配额，共用目录会让 Prime 提前删掉自己的旧备份。
- 备份与同步的数据版本迁移是单向的：不要假设降级后还能读新数据。

## 发布

- 准备版本、写 Release 说明或执行发布前，先读并遵守[发布规范](doc/release-policy.md)（版本一致性核验、签名、CI 测试范围、产物清单都在那里）。
- 用户明确指定的版本和发布范围优先；不得擅自升版、关闭 issue 或更改已发布的 Release。
- Release 说明里的待确认问题只列当前仍开放且需要复查的 issue，发布前重新核对，不要照抄历史名单。

## Android 真机集成测试

先预构建独立测试包，用 `aapt dump badging build/app/outputs/flutter-apk/app-debug.apk` 核实包名为 `io.github.arteiimis.venera.integrationtest`，之后才执行 `flutter test integration_test/... -d ...`。只在 Gradle 里设置独立 applicationId 不够：Flutter 可能读到旧 APK 的正式包名，测试结束会误卸载正式应用。测试前后核对正式应用是否还在。
