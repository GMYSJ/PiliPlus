import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/video/base_quality.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_mixin.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.plPlayerController,
    required this.liveRoomCtr,
    required this.onRefresh,
    this.subTitleStyle = const TextStyle(fontSize: 12),
    this.titleStyle = const TextStyle(fontSize: 14),
  });

  final PlPlayerController plPlayerController;
  final LiveRoomController liveRoomCtr;
  final VoidCallback onRefresh;

  final TextStyle subTitleStyle;
  final TextStyle titleStyle;

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> with HeaderMixin {
  late final LiveRoomController liveRoomCtr = widget.liveRoomCtr;
  @override
  late final PlPlayerController plPlayerController = widget.plPlayerController;
  @override
  ThemeData get theme => ThemeUtils.darkTheme;

  final FocusNode _danmakuFocusNode = FocusNode();
  final TextStyle _hintStyle = const TextStyle(
    color: Color(0x80FFFFFF),
    fontSize: 14,
  );

  @override
  void initState() {
    super.initState();
    // 监听控件显隐，隐藏时自动收起键盘
    ever(plPlayerController.showControls, (bool visible) {
      if (!visible && _danmakuFocusNode.hasFocus) {
        _danmakuFocusNode.unfocus();
        plPlayerController.releaseControls();
      }
    });
  }

  @override
  void dispose() {
    _danmakuFocusNode.dispose();
    super.dispose();
  }

  void _sendDanmaku() {
    final text = liveRoomCtr.danmakuTextController.text.trim();
    if (text.isEmpty) {
      SmartDialog.showToast('请输入弹幕内容');
      return;
    }
    liveRoomCtr.sendDanmakuDirect(text);
    liveRoomCtr.danmakuTextController.clear();
    _danmakuFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13 + bottomPadding),
      child: Material(
        type: .transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // 左侧按钮组宽度估算：播放/暂停 + 刷新 + 弹幕开关 + 弹幕设置 + 画质 + 全屏
            // 右侧按钮组宽度估算：屏蔽 + 画质 + 全屏
            // 输入框最大宽度 320
            final inputMaxWidth = maxWidth > 600 ? 320.0 : maxWidth * 0.45;

            return Row(
              children: [
                PlayOrPauseButton(plPlayerController: plPlayerController),
                ComBtn(
                  height: 30,
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  onTap: widget.onRefresh,
                ),
                // 弹幕输入框（横屏全屏时显示）
                if (isFullScreen) ...[
                  const SizedBox(width: 8),
                  _buildDanmakuInput(inputMaxWidth),
                ],
                const Spacer(),
                // 右侧功能按钮组
                ComBtn(
                  height: 30,
                  tooltip: '屏蔽',
                  icon: const Icon(Icons.block, size: 18, color: Colors.white),
                  onTap: () {
                    if (kDebugMode || liveRoomCtr.isLogin) {
                      Get.toNamed(
                        '/liveDmBlockPage',
                        parameters: {
                          'roomId': liveRoomCtr.roomId.toString(),
                        },
                        arguments: liveRoomCtr,
                      );
                    } else {
                      SmartDialog.showToast('账号未登录');
                    }
                  },
                ),
                const SizedBox(width: 3),
                Obx(
                  () {
                    final enableShowLiveDanmaku =
                        plPlayerController.enableShowLiveDanmaku.value;
                    return ComBtn(
                      height: 30,
                      tooltip: "${enableShowLiveDanmaku ? '关闭' : '开启'}弹幕",
                      icon: enableShowLiveDanmaku
                          ? const Icon(size: 18, CustomIcons.dm_on, color: Colors.white)
                          : const Icon(size: 18, CustomIcons.dm_off, color: Colors.white),
                      onTap: () {
                        final newVal = !enableShowLiveDanmaku;
                        plPlayerController.enableShowLiveDanmaku.value = newVal;
                        if (!plPlayerController.tempPlayerConf) {
                          GStorage.setting.put(
                            SettingBoxKey.enableShowLiveDanmaku,
                            newVal,
                          );
                        }
                      },
                    );
                  },
                ),
                ComBtn(
                  height: 30,
                  tooltip: '弹幕设置',
                  icon: const Icon(size: 18, CustomIcons.dm_settings, color: Colors.white),
                  onTap: () => showSetDanmaku(isLive: true),
                ),
                Obx(
                  () => PopupMenuButton<VideoFitType>(
                    tooltip: '画面比例',
                    initialValue: plPlayerController.videoFit.value,
                    color: Colors.black.withValues(alpha: 0.8),
                    itemBuilder: (context) {
                      return VideoFitType.values
                          .map(
                            (boxFit) => PopupMenuItem<VideoFitType>(
                              height: 35,
                              padding: const EdgeInsets.only(left: 30),
                              value: boxFit,
                              onTap: () => plPlayerController.toggleVideoFit(boxFit),
                              child: Text(
                                boxFit.desc,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          )
                          .toList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        plPlayerController.videoFit.value.desc,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () {
                    final quality = liveRoomCtr.currentQn.value;
                    if (quality == null) {
                      return const SizedBox.shrink();
                    }
                    return PopupMenuButton<LiveQuality>(
                      tooltip: '画质',
                      padding: .zero,
                      initialValue: quality,
                      onSelected: liveRoomCtr.changeQn,
                      color: Colors.black.withValues(alpha: 0.8),
                      itemBuilder: (context) {
                        return liveRoomCtr.acceptQnList
                            .map(
                              (e) => PopupMenuItem<LiveQuality>(
                                height: 35,
                                padding: const EdgeInsets.only(left: 30),
                                value: e,
                                child: Text(
                                  e.desc,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            )
                            .toList();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          quality.desc,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
                if (!plPlayerController.isDesktopPip)
                  ComBtn(
                    height: 30,
                    tooltip: isFullScreen ? '退出全屏' : '全屏',
                    icon: isFullScreen
                        ? const Icon(Icons.fullscreen_exit, size: 24, color: Colors.white)
                        : const Icon(Icons.fullscreen, size: 24, color: Colors.white),
                    onTap: () => plPlayerController.triggerFullScreen(status: !isFullScreen),
                    onSecondaryTap: () => plPlayerController.triggerFullScreen(
                      status: !isFullScreen,
                      inAppFullScreen: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDanmakuInput(double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 120),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x4D000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4D4D4D),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _danmakuFocusNode,
                controller: liveRoomCtr.danmakuTextController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlignVertical: TextAlignVertical.center,
                isDense: true,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: InputBorder.none,
                ),
                hintStyle: _hintStyle,
                obscuringCharacter: '•',
                obscureText: false,
                onTap: () {
                  plPlayerController.holdControls();
                },
                onSubmitted: (_) => _sendDanmaku(),
                onChange: (_) {
                  // 打字时确保控件不隐藏
                  plPlayerController.holdControls();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, size: 18, color: Color(0xFF4D4D4D)),
              onPressed: _sendDanmaku,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}