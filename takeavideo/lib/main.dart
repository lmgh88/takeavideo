import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

import './takevideo/0camera_route.dart';
import './takevideo/1preview_route.dart';
import './takevideo/2commit_route.dart';
import './model/video_model.dart';
import './utils/util.dart';

Future<void> main() async {
  try {
    VideoModel.cameras = await availableCameras();
  } on CameraException catch (error, stackTrace) {
    Util.logError(error.code, error.description);
  }

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_){
    setCustomErrorPage();
    runApp(MainApp());
  });
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.white,
          brightness: Theme.of(context).brightness,
          ),
      routes: {
        '/': (context) => CameraHome(),
        '/preview': (context) => PreviewRoute(),
        '/commit': (context) => CommitRoute(),
      },
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}

void setCustomErrorPage() async{
  ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails){
    print(flutterErrorDetails.toString());
    return Center(
      child: Text('我走神了~'),
    );
  };
}
