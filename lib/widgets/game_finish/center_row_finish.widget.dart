import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:thinking_battle/providers/common.provider.dart';
import 'package:thinking_battle/providers/game.provider.dart';
import 'package:thinking_battle/screens/game_start.screen.dart';
import 'package:thinking_battle/screens/mode_select.screen.dart';

class CenterRowFinish extends HookWidget {
  final bool? winFlg;

  const CenterRowFinish({
    Key? key,
    required this.winFlg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioCache soundEffect = useProvider(soundEffectProvider).state;
    final double seVolume = useProvider(seVolumeProvider).state;
    final String friendMatchWord = useProvider(friendMatchWordProvider).state;
    final bool friendMatchFlg = friendMatchWord != '';

    return Column(
      children: [
        Text(
          winFlg == null
              ? '引き分け！'
              : winFlg!
                  ? 'あなたの勝ち！'
                  : 'あなたの負け！',
          style: TextStyle(
            color: winFlg == null
                ? Colors.green.shade200
                : winFlg!
                    ? Colors.blue.shade200
                    : Colors.red.shade200,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            shadows: <Shadow>[
              Shadow(
                color: Colors.grey.shade800,
                offset: const Offset(3, 3),
                blurRadius: 3.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  child: const Text('戻る'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red.shade600,
                    padding: const EdgeInsets.only(
                      bottom: 3,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      width: 2,
                      color: Colors.red.shade700,
                    ),
                  ),
                  onPressed: () {
                    soundEffect.play(
                      'sounds/tap.mp3',
                      isNotification: true,
                      volume: seVolume,
                    );

                    if (context.read(changedTrainingProvider).state) {
                      context.read(changedTrainingProvider).state = false;
                      context.read(trainingProvider).state = false;
                    }

                    Navigator.popUntil(
                      context,
                      ModalRoute.withName(ModeSelectScreen.routeName),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  child: Text(friendMatchFlg ? 'もう一回' : '次のゲーム'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue.shade500,
                    padding: const EdgeInsets.only(
                      bottom: 3,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      width: 2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  onPressed: () {
                    context.read(bgmProvider).state.stop();
                    soundEffect.play(
                      'sounds/tap.mp3',
                      isNotification: true,
                      volume: seVolume,
                    );

                    if (context.read(changedTrainingProvider).state) {
                      context.read(changedTrainingProvider).state = false;
                      context.read(trainingProvider).state = false;
                    }

                    Navigator.popUntil(
                      context,
                      ModalRoute.withName(ModeSelectScreen.routeName),
                    );
                    Navigator.of(context).pushNamed(
                      GameStartScreen.routeName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
