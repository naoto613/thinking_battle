import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:thinking_battle/services/common/get_random_skills.service.dart';
import 'package:thinking_battle/services/game_start/matching_flow.service.dart';
import 'package:thinking_battle/widgets/common/background.widget.dart';
import 'package:thinking_battle/models/player_info.model.dart';
import 'package:thinking_battle/services/game_start/initialize_game.service.dart';

import 'package:thinking_battle/providers/common.provider.dart';
import 'package:thinking_battle/providers/game.provider.dart';
import 'package:thinking_battle/providers/player.provider.dart';
import 'package:thinking_battle/widgets/common/user_profile_random_skills.widget.dart';

import 'package:thinking_battle/widgets/game_start/center_row_start.widget.dart';
import 'package:thinking_battle/widgets/game_start/top_row_start.widget.dart';
import 'package:thinking_battle/widgets/common/user_profile_common.widget.dart';

class GameStartScreen extends HookWidget {
  const GameStartScreen({Key? key}) : super(key: key);
  static const routeName = '/game-start';

  @override
  Widget build(BuildContext context) {
    final String fiendMatchWord = useProvider(friendMatchWordProvider).state;

    final AudioCache soundEffect = useProvider(soundEffectProvider).state;
    final double seVolume = useProvider(seVolumeProvider).state;

    final PlayerInfo rivalInfo = useProvider(rivalInfoProvider).state;

    final int imageNumber = useProvider(imageNumberProvider).state;
    final int cardNumber = useProvider(cardNumberProvider).state;

    final int matchedCount = useProvider(matchedCountProvider).state;
    final int continuousWinCount =
        useProvider(continuousWinCountProvider).state;
    final String playerName = useProvider(playerNameProvider).state;
    final double rate = useProvider(rateProvider).state;
    List<int> mySkillIdsList = useProvider(mySkillIdsListProvider).state;
    final int trainingStatus = context.read(trainingStatusProvider).state;
    final double bgmVolume = useProvider(bgmVolumeProvider).state;
    final bool initialTutorialFlg =
        context.read(initialTutorialFlgProvider).state;

    final ValueNotifier<bool> matchingQuitFlg = useState(false);

    final ValueNotifier<bool> interruptionFlgState = useState(false);
    final ValueNotifier<bool> matchingAnimatedFlgState = useState(false);

    final bool widthOk = MediaQuery.of(context).size.width > 350;
    final double wordMinusSize = widthOk ? 0 : 1.5;

    // イベントマッチ判定
    // final bool isEventMatch = useProvider(isEventMatchProvider).state;

    useEffect(() {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        context.read(rivalInfoProvider).state = dummyPlayerInfo;
        context.read(matchingWaitingIdProvider).state = '';
        context.read(matchingRoomIdProvider).state = '';

        await Future.delayed(
          const Duration(milliseconds: 500),
        );
        context.read(bgmProvider).state = await soundEffect.loop(
          'sounds/waiting_matching.mp3',
          volume: bgmVolume,
          isNotification: true,
        );

        if (!matchingQuitFlg.value) {
          if (trainingStatus >= 1) {
            await Future.delayed(
              const Duration(milliseconds: 1500),
            );
            if (initialTutorialFlg) {
              tutorialTrainingInitialAction(
                context,
              );

              tutorialGameStart(
                context,
                soundEffect,
                seVolume,
                matchingAnimatedFlgState,
              );
            } else if (!matchingQuitFlg.value) {
              trainingInitialAction(
                context,
              );

              gameStart(
                context,
                soundEffect,
                seVolume,
                matchingAnimatedFlgState,
              );
            }
          } else {
            // イベントマッチの場合、ランダムスキルを設定
            // if (context.read(isEventMatchProvider).state) {
            //   final randomSkills = getRandomSkills();
            //   mySkillIdsList = randomSkills;
            //   context.read(randomSkillIdsListProvider).state = randomSkills;
            // }

            await matchingFlow(
              context,
              imageNumber,
              cardNumber,
              playerName,
              rate,
              matchedCount,
              continuousWinCount,
              mySkillIdsList,
              matchingQuitFlg,
              fiendMatchWord,
              interruptionFlgState,
              matchingAnimatedFlgState,
              soundEffect,
              seVolume,
            );
          }
        }
      });
      return null;
    }, const []);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            background(),
            Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // const Stamina(),
                      // context.read(isEventMatchProvider).state
                      //     ? Padding(
                      //         padding: const EdgeInsets.only(top: 15.0),
                      //         child: Text(
                      //           'ランダムスキルマッチ',
                      //           style: TextStyle(
                      //             fontSize: 24,
                      //             fontFamily: 'MochiyPopOne',
                      //             color: Colors.purple.shade100,
                      //             shadows: const [
                      //               Shadow(
                      //                 color: Colors.black,
                      //                 offset: Offset(1, 1),
                      //                 blurRadius: 1,
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       )
                      //     : Container(),
                      // const SizedBox(height: 30),
                      TopRowStart(
                        matchingFlg: rivalInfo.skillList.isNotEmpty,
                      ),
                      rivalInfo.skillList.isNotEmpty
                          // rivalInfo.skillList.isEmpty
                          ? AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: matchingAnimatedFlgState.value ? 1 : 0,
                              child:
                                  // isEventMatch
                                  //     ? UserProfileRandomSkills(
                                  //         imageNumber: rivalInfo.imageNumber,
                                  //         cardNumber: rivalInfo.cardNumber,
                                  //         matchedCount: rivalInfo.matchedCount,
                                  //         continuousWinCount:
                                  //             rivalInfo.continuousWinCount,
                                  //         playerName: rivalInfo.name,
                                  //         userRate: rivalInfo.rate,
                                  //         mySkillIdsList: rivalInfo.skillList,
                                  //         wordMinusSize: wordMinusSize,
                                  //       )
                                  //     :
                                  UserProfileCommon(
                                imageNumber: rivalInfo.imageNumber,
                                cardNumber: rivalInfo.cardNumber,
                                matchedCount: rivalInfo.matchedCount,
                                continuousWinCount:
                                    rivalInfo.continuousWinCount,
                                playerName: rivalInfo.name,
                                userRate: rivalInfo.rate,
                                mySkillIdsList: rivalInfo.skillList,
                                wordMinusSize: wordMinusSize,
                              ),
                            )
                          : SizedBox(
                              height: widthOk ? 158 : 148,
                              child: fiendMatchWord != ''
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 30,
                                            child: Text(
                                              'あいことば',
                                              style: TextStyle(
                                                color: Colors.blueGrey.shade100,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            fiendMatchWord,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'KaiseiOpti',
                                              fontSize: 35,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                      CenterRowStart(
                        matchingFinishedFlg: rivalInfo.skillList.isNotEmpty,
                        soundEffect: soundEffect,
                        seVolume: seVolume,
                        matchingQuitFlg: matchingQuitFlg,
                        initialTutorialFlg: initialTutorialFlg,
                      ),
                      // isEventMatch
                      //     ? UserProfileRandomSkills(
                      //         imageNumber: imageNumber,
                      //         cardNumber: cardNumber,
                      //         matchedCount: matchedCount,
                      //         continuousWinCount: continuousWinCount,
                      //         playerName: playerName,
                      //         userRate: rate,
                      //         mySkillIdsList: mySkillIdsList,
                      //         wordMinusSize: wordMinusSize,
                      //       )
                      //     :
                      UserProfileCommon(
                        imageNumber: imageNumber,
                        cardNumber: cardNumber,
                        matchedCount: matchedCount,
                        continuousWinCount: continuousWinCount,
                        playerName: playerName,
                        userRate: rate,
                        mySkillIdsList: mySkillIdsList,
                        wordMinusSize: wordMinusSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
