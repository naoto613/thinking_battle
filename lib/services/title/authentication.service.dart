import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinking_battle/screens/mode_select.screen.dart';
import 'package:thinking_battle/widgets/common/failed_loading.widget.dart';

Future signUp(
  BuildContext context,
) async {
  EasyLoading.show(status: 'loading...');

  try {
    // メール/パスワードでユーザー登録
    final FirebaseAuth auth = FirebaseAuth.instance;

    final String email = randomString(16);
    final String password = randomString(16);

    await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // ユーザー登録に成功した場合

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('email', email);
    prefs.setString('password', password);

    // TODO 遊び方にとぶ
    await Navigator.of(context).pushNamed(
      ModeSelectScreen.routeName,
    );
  } catch (e) {
    // ユーザー登録に失敗した場合
    AwesomeDialog(
      context: context,
      dialogType: DialogType.NO_HEADER,
      headerAnimationLoop: false,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      showCloseIcon: true,
      animType: AnimType.SCALE,
      width: MediaQuery.of(context).size.width * .86 > 650 ? 650 : null,
      body: const FaildLoading(),
    ).show();
  }
  EasyLoading.dismiss();
}

Future login(
  BuildContext context,
) async {
  try {
    // メール/パスワードでログイン
    final FirebaseAuth auth = FirebaseAuth.instance;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? email = prefs.getString('email');
    final String? password = prefs.getString('password');

    await auth.signInWithEmailAndPassword(
      email: email!,
      password: password!,
    );
    // ログインに成功した場合
    // チャット画面に遷移＋ログイン画面を破棄
    await Navigator.of(context).pushNamed(
      ModeSelectScreen.routeName,
    );
  } catch (e) {
    // ログインに失敗した場合
    AwesomeDialog(
      context: context,
      dialogType: DialogType.NO_HEADER,
      headerAnimationLoop: false,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      showCloseIcon: true,
      animType: AnimType.SCALE,
      width: MediaQuery.of(context).size.width * .86 > 650 ? 650 : null,
      body: const FaildLoading(),
    ).show();
  }
}

String randomString(int length) {
  const _randomChars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const _charsLength = _randomChars.length;

  final rand = Random();
  final codeUnits = List.generate(
    length,
    (index) {
      final n = rand.nextInt(_charsLength);
      return _randomChars.codeUnitAt(n);
    },
  );
  return String.fromCharCodes(codeUnits);
}