import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:thinking_battle/providers/player.provider.dart';
import 'package:thinking_battle/widgets/common/edit_image.widget.dart';
import 'package:thinking_battle/widgets/mode_select/my_room/edit_theme.widget.dart';
import 'package:thinking_battle/widgets/mode_select/my_room/my_data.widget.dart';
import 'package:thinking_battle/widgets/mode_select/my_room/setting_my_messages.widget.dart';

import 'package:thinking_battle/widgets/mode_select/my_room/setting_my_skills.widget.dart';

class MyRoomButton extends HookWidget {
  final AudioCache soundEffect;
  final double seVolume;
  final List colorList;
  final String selectWord;

  // ignore: use_key_in_widget_constructors
  const MyRoomButton(
    this.soundEffect,
    this.seVolume,
    this.colorList,
    this.selectWord,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorList[0][1].withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        title: Text(
          selectWord,
          style: TextStyle(
            color: colorList[1] ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'KaiseiOpti',
          ),
        ),
        onTap: () {
          soundEffect.play(
            'sounds/tap.mp3',
            isNotification: true,
            volume: seVolume,
          );
          selectWord == 'マイデータ'
              ? AwesomeDialog(
                  context: context,
                  dialogType: DialogType.NO_HEADER,
                  headerAnimationLoop: false,
                  dismissOnTouchOutside: true,
                  dismissOnBackKeyPress: true,
                  showCloseIcon: false,
                  animType: AnimType.SCALE,
                  width: MediaQuery.of(context).size.width * .86 > 650
                      ? 650
                      : null,
                  body: const MyData(),
                ).show()
              : AwesomeDialog(
                  context: context,
                  dialogType: DialogType.NO_HEADER,
                  headerAnimationLoop: false,
                  dismissOnTouchOutside: true,
                  dismissOnBackKeyPress: true,
                  showCloseIcon: true,
                  animType: AnimType.SCALE,
                  width: MediaQuery.of(context).size.width * .86 > 650
                      ? 650
                      : null,
                  body: selectWord == 'アイコン'
                      ? const EditImage()
                      : selectWord == 'テーマ'
                          ? const EditTheme()
                          : selectWord == 'スキル'
                              ? SettingMySkills(
                                  [
                                    ...context
                                        .read(mySkillIdsListProvider)
                                        .state
                                  ],
                                  soundEffect,
                                  seVolume,
                                )
                              : selectWord == 'メッセージ'
                                  ? SettingMyMessages(
                                      [
                                        ...context
                                            .read(myMessageIdsListProvider)
                                            .state
                                      ],
                                      soundEffect,
                                      seVolume,
                                    )
                                  : null,
                ).show();
        },
      ),
    );
  }
}
