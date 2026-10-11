import 'dart:math' as math;

import 'package:PiliPlus/common/widgets/custom_icon.dart';
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

  late final TextEditingController dmInputController = TextEditingController();

  @override
  void dispose() {
    dmInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 6,
        bottom: 6 + bottomInset,
      ),
      child: Material(
        type: .transparency,
        child: Row(
          children: [
            PlayOrPauseButton(plPlayerController: plPlayerController),
            ComBtn(
              height: 30,
              tooltip: '刷新',
              icon: const Icon(
                Icons.refresh,
                size: 18,
                color: Colors.white,
              ),
              onTap: widget.onRefresh,
            ),
            if (isFullScreen)
              Flexible(fit: FlexFit.loose, child: _buildLiveDmInput())
            else
              const Spacer(),
            ComBtn(
              height: 30,
              tooltip: '屏蔽',
              icon: const Icon(
                size: 18,
                Icons.block,
                color: Colors.white,
              ),
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
                      ? const Icon(
                          size: 18,
                          CustomIcons.dm_on,
                          color: Colors.white,
                        )
                      : const Icon(
                          size: 18,
                          CustomIcons.dm_off,
                          color: Colors.white,
                        ),
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
              icon: const Icon(
                size: 18,
                CustomIcons.dm_settings,
                color: Colors.white,
              ),
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
                          onTap: () =>
                              plPlayerController.toggleVideoFit(boxFit),
                          child: Text(
                            boxFit.desc,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    plPlayerController.videoFit.value.desc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Obx(
              () => PopupMenuButton<int>(
                tooltip: '画质',
                padding: EdgeInsets.zero,
                initialValue: liveRoomCtr.currentQn,
                color: Colors.black.withValues(alpha: 0.8),
                itemBuilder: (context) {
                  return liveRoomCtr.acceptQnList
                      .map(
                            (e) => PopupMenuItem<int>(
                              height: 35,
                              padding: const EdgeInsets.only(left: 30),
                              value: e.code,
                              onTap: () => liveRoomCtr.changeQn(e.code),
                              child: Text(
                                e.desc,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                      .toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    liveRoomCtr.currentQnDesc.value,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
            if (!plPlayerController.isDesktopPip)
              ComBtn(
                height: 30,
                tooltip: isFullScreen ? '退出全屏' : '全屏',
                icon: isFullScreen
                    ? const Icon(
                        Icons.fullscreen_exit,
                        size: 24,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.fullscreen,
                        size: 24,
                        color: Colors.white,
                      ),
                onTap: () =>
                    plPlayerController.triggerFullScreen(status: !isFullScreen),
                onSecondaryTap: () => plPlayerController.triggerFullScreen(
                  status: !isFullScreen,
                  inAppFullScreen: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 横屏全屏状态下、底部控制栏内置的弹幕输入框:
  /// 通过 LayoutBuilder 约束最大宽度,避免铺满整行;并与弹幕总开关联动。
  Widget _buildLiveDmInput() {
    return Obx(
      () {
        if (!plPlayerController.enableShowLiveDanmaku.value) {
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final double available = constraints.maxWidth;
            if (!available.isFinite || available < 160) {
              return const SizedBox.shrink();
            }
            final double width = math.min(320.0, available);
            return Center(
              child: Container(
                width: width,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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
                        controller: dmInputController,
                        focusNode: liveRoomCtr.danmakuInputFocusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        cursorColor: Colors.white,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: '输入弹幕内容',
                          hintStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitLiveDm(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ComBtn(
                      height: 40,
                      tooltip: '发送',
                      icon: const Icon(
                        Icons.send,
                        size: 18,
                        color: Colors.white,
                      ),
                      onTap: () => _submitLiveDm(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitLiveDm() async {
    if (await liveRoomCtr.sendLiveDanmaku(dmInputController.text)) {
      dmInputController.clear();
    }
  }
}
