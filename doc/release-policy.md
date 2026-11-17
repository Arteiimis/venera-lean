# Release 发布规范（venera-lean）

本仓库独立发行，不走上游的六平台机器人流程。发布由 `.github/workflows/release.yml` 完成，只构建两个平台：Android（4 个签名 APK）与 Windows（便携 ZIP）。

## 版本与标签

- 版本线为 CalVer：`年.月.序号`，构建号单独递增（`pubspec.yaml` 的 `+<build>`）。
- `pubspec.yaml` 版本、`lib/foundation/app.dart` 的 `final version`、`doc/release-<ver>.md` 首行 `# Venera Prime <ver>`、git tag `v<ver>` 四处必须一致；核验：`RELEASE_TAG=v<ver> python3 tool/check_version.py`。
- 不得复用上游已有的 `v2.x` 标签；本仓库的版本一律 `v<CalVer>`。

## 发布流程

1. 提交并推送 `master`，确认 CI 的 `checks` 任务（analyze + test）通过。
2. 写 `doc/release-<ver>.md`：`## 本次更新`（每项写清入口与可观察行为）、`## 请更新后验证并反馈`、`## 验证范围`（只写实际执行过的检查，区分模拟与真机）。
3. 打标签并推送：`git tag v<ver> && git push origin v<ver>`。工作流会自动构建、生成 `SHA256SUMS`、创建 GitHub Release。
4. `workflow_dispatch` 手动触发只构建产物、不发布 Release，用于验证流水线。

## 签名与凭据

- Android 使用本仓库自己的 keystore：GitHub Secrets `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。
- 本地构建在 `android/key.properties` 填同样四项；`key.properties` 与 `*.jks` 由 `android/.gitignore` 忽略，绝不入库。
- 证书指纹（SHA-256）：`D6:32:95:48:5F:EE:A3:76:34:36:FA:C0:76:51:35:07:69:E2:BF:5B:F6:0A:9A:02:42:71:8D:4E:68:AA:99:ED`。
- 签名一旦对外发布便不可更换：已安装设备只能同签名升级，换签名等于要求用户卸载重装并丢失应用内数据。

## 产物

| 平台 | 附件 |
| --- | --- |
| Android | `venera-lean-<ver>-arm64-v8a.apk`、`venera-lean-<ver>-armeabi-v7a.apk`、`venera-lean-<ver>-x86_64.apk`、`venera-lean-<ver>.apk`（universal） |
| Windows | `venera-lean-<ver>-windows-x64.zip`（便携） |
| 其他 | `SHA256SUMS` |

## 应用内更新

更新检查（`lib/foundation/app_update.dart`）只接受本仓库 `releases/download/` 下的资产，按文件名后缀 `-<abi>.apk` 选择架构，universal 包作为回退。发布时不要修改这条文件名规则。
