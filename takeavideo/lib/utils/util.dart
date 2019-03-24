import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Util {
  static void logError(String code, [String message = ""]) =>
      print('Error: $code\nError Message: $message');

  static void showInSnackBar(
      GlobalKey<ScaffoldState> scaffoldKey, String message) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[Text(message)],
      ),
      duration: Duration(milliseconds: 1500),
    ));
  }

  static void showToast(String message) {
    Fluttertoast.showToast(msg: message, gravity: ToastGravity.CENTER);
  }

  static String version;
}