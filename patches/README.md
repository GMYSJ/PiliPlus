# 横屏底部弹幕输入框（弹幕框）

只改了 4 个文件：

```
lib/pages/live_room/controller.dart
lib/pages/live_room/widgets/bottom_control.dart
lib/pages/live_room/widgets/header_control.dart
lib/plugin/pl_player/controller.dart
```

## 方式一：GitHub Actions 一键（推荐）

仓库 Actions → `Build with Danmaku Box` → Run workflow：

- `upstream_tag` 填版本号（如 `2.2.0.2`），留空自动取上游最新 release
- `make_release` 勾选则额外生成 Release 挂 APK

它做的事：checkout 上游那个 tag 的干净源码 → 把你 fork 里的这 4 个文件覆盖上去 → 编译 Android APK。

上游升版不需要手动 merge。

## 方式二：本地打补丁

```bash
git clone https://github.com/bggRGjQaUbCoE/PiliPlus.git
cd PiliPlus
git checkout <版本tag>
git apply --3way /path/to/live-danmaku-box.patch
flutter build apk --release --split-per-abi
```

`--3way` 可以在上游有小幅改动时尽量自动合并；冲突时按提示手工解决。
