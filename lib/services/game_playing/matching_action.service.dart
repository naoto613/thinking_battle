import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinking_battle/models/matching_info.model.dart';
import 'package:thinking_battle/models/player_info.model.dart';

import 'package:thinking_battle/providers/game.provider.dart';
import 'package:thinking_battle/providers/player.provider.dart';
import 'package:thinking_battle/screens/mode_select.screen.dart';
import 'package:thinking_battle/services/game_playing/initialize_game.service.dart';
import 'package:thinking_battle/services/game_playing/update_rate.service.dart';
import 'package:thinking_battle/widgets/game_start/failed_matching.widget.dart';

Future matchingAction(
  BuildContext context,
  int imageNumber,
  String userName,
  double userRate,
  double maxRate,
  int matchedCount,
  int continuousWinCount,
  List<int> userSkillIdsList,
  ValueNotifier<bool> matchingQuitFlgState,
  String friendMatchWord,
) async {
  await mainMatchingAction(
    context,
    imageNumber,
    userName,
    userRate,
    maxRate,
    matchedCount,
    continuousWinCount,
    userSkillIdsList,
    matchingQuitFlgState,
    friendMatchWord,
  ).catchError((onError) async {
    if (onError.toString() == 'Exception: 通信失敗') {
      throw Exception('通信失敗');
    } else {
      // 通信失敗以外は再度マッチング処理を行う
      await matchingAction(
        context,
        imageNumber,
        userName,
        userRate,
        maxRate,
        matchedCount,
        continuousWinCount,
        userSkillIdsList,
        matchingQuitFlgState,
        friendMatchWord,
      );
    }
  });
}

Future mainMatchingAction(
  BuildContext context,
  int imageNumber,
  String userName,
  double userRate,
  double maxRate,
  int matchedCount,
  int continuousWinCount,
  List<int> userSkillIdsList,
  ValueNotifier<bool> matchingQuitFlgState,
  String friendMatchWord,
) async {
  final randomMatchFlg = friendMatchWord == '';

  if (randomMatchFlg) {
    // ランダムマッチ
    final matchingRoomRef =
        FirebaseFirestore.instance.collection('random-matching-room');

    await matchingRoomRef
        .where('matchingStatus', isEqualTo: 1)
        .where('rate', isLessThan: userRate + 500.0)
        .where('rate', isGreaterThan: userRate - 500.0)
        .limit(1)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      await actionAfterSearch(
        querySnapshot,
        matchingRoomRef,
        context,
        userName,
        userRate,
        maxRate,
        imageNumber,
        matchedCount,
        continuousWinCount,
        userSkillIdsList,
        matchingQuitFlgState,
        context.read(loginIdProvider).state,
        friendMatchWord,
      );
    }).catchError((error) async {
      // データ取得に失敗した場合
      throw Exception('通信失敗');
    });
  } else {
    final friendMatchingRoomRef =
        FirebaseFirestore.instance.collection('friend-matching-room');

    // フレンドマッチ
    await friendMatchingRoomRef
        .where('matchingStatus', isEqualTo: 1)
        .where('customData', isEqualTo: friendMatchWord)
        .limit(1)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      await actionAfterSearch(
        querySnapshot,
        friendMatchingRoomRef,
        context,
        userName,
        userRate,
        maxRate,
        imageNumber,
        matchedCount,
        continuousWinCount,
        userSkillIdsList,
        matchingQuitFlgState,
        context.read(loginIdProvider).state,
        friendMatchWord,
      );
    }).catchError((error) async {
      // データ取得に失敗した場合
      throw Exception('通信失敗');
    });
  }
}

Future actionAfterSearch(
  QuerySnapshot querySnapshot,
  CollectionReference<Map<String, dynamic>> matchingRoomRef,
  BuildContext context,
  String userName,
  double userRate,
  double maxRate,
  int imageNumber,
  int matchedCount,
  int continuousWinCount,
  List<int> userSkillIdsList,
  ValueNotifier<bool> matchingQuitFlgState,
  String matchingId,
  String friendMatchWord,
) async {
  if (querySnapshot.docs.isEmpty) {
    await matchingPreparation(
      matchingRoomRef,
      matchingId,
      context,
      userName,
      userRate,
      maxRate,
      imageNumber,
      matchedCount,
      continuousWinCount,
      userSkillIdsList,
      matchingQuitFlgState,
      friendMatchWord,
    );
  } else {
    // トランザクション制御を行ってステータスを更新
    await matchingUpdate(
      matchingRoomRef,
      querySnapshot.docs[0].id,
      context,
      imageNumber,
      userName,
      userRate,
      maxRate,
      matchedCount,
      continuousWinCount,
      userSkillIdsList,
      matchingQuitFlgState,
    );
  }
}

Future matchingPreparation(
  CollectionReference<Map<String, dynamic>> matchingRoomRef,
  String matchingId,
  BuildContext context,
  String userName,
  double userRate,
  double maxRate,
  int imageNumber,
  int matchedCount,
  int continuousWinCount,
  List<int> userSkillIdsList,
  ValueNotifier<bool> matchingQuitFlgState,
  String friendMatchWord,
) async {
  final bool precedingFlg = Random().nextInt(2) == 0 ? true : false;
  final randomMatchFlg = friendMatchWord == '';

  // 待機中のデータを作る
  await matchingRoomRef.doc(matchingId).set({
    'name': userName,
    'rate': userRate,
    'maxRate': maxRate,
    'imageNumber': imageNumber,
    'matchedCount': matchedCount,
    'continuousWinCount': continuousWinCount,
    'skillList': userSkillIdsList,
    'matchingStatus': 1, // 待機中
    'precedingFlg': precedingFlg,
    'customData': randomMatchFlg ? DateTime.now().toString() : friendMatchWord,
  }).then((_) async {
    // providerに登録
    context.read(matchingWaitingIdProvider).state = matchingId;

    // 変更をlisten
    var listen = matchingRoomRef
        .doc(matchingId)
        .snapshots()
        .listen((DocumentSnapshot<Object?> querySnapshot) {
      MatchingInfo matchingInfoSnapshot = MatchingInfo.fromJson(querySnapshot);

      if (matchingInfoSnapshot.matchingStatus == 2 &&
          !matchingQuitFlgState.value) {
        // ライバル情報を更新
        context.read(rivalInfoProvider).state = PlayerInfo(
          name: matchingInfoSnapshot.name,
          rate: matchingInfoSnapshot.rate,
          maxRate: matchingInfoSnapshot.maxRate,
          imageNumber: matchingInfoSnapshot.imageNumber,
          matchedCount: matchingInfoSnapshot.matchedCount,
          continuousWinCount: matchingInfoSnapshot.continuousWinCount,
          skillList: matchingInfoSnapshot.skillList,
        );

        // マッチ済みに更新
        matchingRoomRef.doc(matchingId).set({
          "matchingStatus": 3,
        }).then((void _) async {
          // マッチング完了
          context.read(matchingRoomIdProvider).state = matchingId;
          context.read(matchingWaitingIdProvider).state = '';
          context.read(precedingFlgProvider).state = precedingFlg;

          if (context.read(friendMatchWordProvider).state != '') {
            // 負けた場合のレートを登録
            final double failedRate = getNewRate(
              userRate,
              matchingInfoSnapshot.rate,
              false,
            );

            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setDouble('failedRate', failedRate);
          }

          matchingRoomRef.doc(matchingId).delete().catchError((error) {
            // データ削除に失敗した場合、何もしない
          });
          return;
        }).catchError((error) async {
          // データ更新に失敗した場合
          throw Exception('通信失敗');
        });
      }
    });

    if (randomMatchFlg) {
      for (int i = 0; i < 99; i++) {
        if (matchingQuitFlgState.value ||
            context.read(matchingWaitingIdProvider).state == '') {
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      listen.cancel();

      if (!matchingQuitFlgState.value &&
          context.read(matchingWaitingIdProvider).state != '') {
        matchingRoomRef.doc(matchingId).delete().catchError((error) async {
          // データ削除に失敗した場合は何もしない
        });

        context.read(matchingWaitingIdProvider).state = '';

        // とりあえずCPUとマッチングさせる
        context.read(trainingProvider).state = true;
        context.read(changedTrainingProvider).state = true;
        trainingInitialAction(
          context,
        );

        return;
      }
    } else {
      for (int i = 0; i < 100; i++) {
        if (matchingQuitFlgState.value ||
            context.read(matchingWaitingIdProvider).state == '') {
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      listen.cancel();

      if (!matchingQuitFlgState.value &&
          context.read(matchingWaitingIdProvider).state != '') {
        matchingRoomRef.doc(matchingId).delete().catchError((error) async {
          // データ削除に失敗した場合は何もしない
        });

        context.read(matchingWaitingIdProvider).state = '';

        // 戻る
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR,
          headerAnimationLoop: false,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          animType: AnimType.SCALE,
          width: MediaQuery.of(context).size.width * .86 > 650 ? 650 : null,
          body: const FaildMatching(
            'マッチング失敗',
            'あいことばは一致していますか？\nメニュー画面に戻ります。',
          ),
        ).show();

        matchingQuitFlgState.value = true;

        await Future.delayed(
          const Duration(milliseconds: 3500),
        );
        Navigator.popUntil(
            context, ModalRoute.withName(ModeSelectScreen.routeName));

        return;
      }
    }
  }).catchError((error) async {
    // データ登録に失敗した場合
    throw Exception('通信失敗');
  });
}

Future matchingUpdate(
  CollectionReference<Map<String, dynamic>> matchingRoomRef,
  String matchingId,
  BuildContext context,
  int imageNumber,
  String userName,
  double userRate,
  double maxRate,
  int matchedCount,
  int continuousWinCount,
  List<int> userSkillIdsList,
  ValueNotifier<bool> matchingQuitFlgState,
) async {
  // マッチング待機中のプレイヤーを取得
  final matchingTargetRef = matchingRoomRef.doc(matchingId);

  MatchingInfo firstMatchedInfoSnapshot;

  try {
    firstMatchedInfoSnapshot =
        await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot<Map<String, dynamic>> matchingTargetDoc =
          await transaction.get(matchingTargetRef);

      if (!matchingTargetDoc.exists) {
        throw Exception('トランザクション取得対象なし');
      }

      MatchingInfo firstMatchingInfoSnapshot =
          MatchingInfo.fromJson(matchingTargetDoc);

      if (!matchingQuitFlgState.value &&
          firstMatchingInfoSnapshot.matchingStatus == 1) {
        // 連携済みに更新
        transaction.update(matchingTargetRef, {
          'name': userName,
          'rate': userRate,
          'maxRate': maxRate,
          'imageNumber': imageNumber,
          'matchedCount': matchedCount,
          'continuousWinCount': continuousWinCount,
          'skillList': userSkillIdsList,
          'matchingStatus': 2, // マッチング
        });

        return firstMatchingInfoSnapshot;
      } else {
        throw Exception('ステータス更新済');
      }
    });
  } catch (e, s) {
    throw Exception('トランザクション失敗');
  }

  // 変更をlisten
  var listen = matchingTargetRef
      .snapshots()
      .listen((DocumentSnapshot<Object?> querySnapshot) async {
    if (!matchingQuitFlgState.value &&
        querySnapshot['matchingStatus'] as int == 3) {
      // ライバル情報を更新
      context.read(rivalInfoProvider).state = PlayerInfo(
        name: firstMatchedInfoSnapshot.name,
        rate: firstMatchedInfoSnapshot.rate,
        maxRate: firstMatchedInfoSnapshot.maxRate,
        imageNumber: firstMatchedInfoSnapshot.imageNumber,
        matchedCount: firstMatchedInfoSnapshot.matchedCount,
        continuousWinCount: firstMatchedInfoSnapshot.continuousWinCount,
        skillList: firstMatchedInfoSnapshot.skillList,
      );

      // 部屋のIDを取得
      context.read(matchingRoomIdProvider).state = matchingId;
      // 先行フラグの反対値を設定
      context.read(precedingFlgProvider).state =
          !firstMatchedInfoSnapshot.precedingFlg;

      if (context.read(friendMatchWordProvider).state != '') {
        // 負けた場合のレートを登録
        final double failedRate = getNewRate(
          userRate,
          firstMatchedInfoSnapshot.rate,
          false,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setDouble('failedRate', failedRate);
      }

      return;
    }
  });

  for (int i = 0; i < 3; i++) {
    if (context.read(matchingRoomIdProvider).state != '') {
      break;
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  listen.cancel();

  if (!matchingQuitFlgState.value &&
      context.read(matchingRoomIdProvider).state == '') {
    matchingTargetRef.delete().catchError((error) async {
      // データ削除に失敗した場合は何もしない
    });

    throw Exception('相手からの返答なし');
  }
}