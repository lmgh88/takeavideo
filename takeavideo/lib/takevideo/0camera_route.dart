import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../model/video_model.dart';
import '../model/user_model.dart';
import '../utils/util.dart';

class CameraHome extends StatefulWidget {
  @override
  _CameraHomeState createState() {
    return _CameraHomeState();
  }
}

class _CameraHomeState extends State<CameraHome> {
  CameraController controller;
  String imagePath;
  String videoPath;
  String videoFileName;

  var videoResolution = VideoModel.useMediumResolution
      ? ResolutionPreset.medium
      : ResolutionPreset.high;

  VoidCallback videoPlayerListener;

  int cameraIndex;
  int videoAllSeconds = 0;
  int videoSeconds;
  int videoMinutes;
  Timer videoTimer;
  String videoTimeStr = '';

  String addZero(int num) {
    return num > 9 ? '$num' : '0$num';
  }

  @override
  void initState() {
    if (VideoModel.cameras.isNotEmpty) {
      onNewCameraSelected();
    }
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
            child: Stack(
              children: <Widget>[
                Center(
                  child: _cameraPreviewWidget(),
                ),
                Positioned(
                  top: 25.0,
                  width: MediaQuery.of(context).size.width,
                  child: Align(
                    alignment: FractionalOffset.topCenter,
                    child: Text(
                      videoTimeStr,
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
                  ),
                ),
                Positioned(
                  child: IconButton(
                    icon: Icon(Icons.autorenew),
                    color: Colors.white,
                    iconSize: 35.0,
                    onPressed:
                    controller != null && controller.value.isRecordingVideo
                        ? null
                        : onNewCameraSelected,
                  ),
                  top: 10,
                  right: 20,
                ),
                Positioned(
                  bottom: 0,
                  width: MediaQuery.of(context).size.width,
                  child: Align(
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.videocam),
                        color:
                        (controller != null && controller.value.isInitialized)
                            ? (!controller.value.isRecordingVideo
                            ? Colors.white
                            : Colors.red)
                            : Colors.white,
                        onPressed:
                        (controller != null && controller.value.isInitialized)
                            ? (!controller.value.isRecordingVideo
                            ? onRecordButtonPressed
                            : onStopButtonPressed)
                            : null,
                        iconSize: 50.0,
                      ),
                    ),
                    alignment: FractionalOffset.bottomCenter,
                  ),
                ),
              ],
            ),
            color: Colors.black,
          )),
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        '请选择摄像头',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onNewCameraSelected() async {
    CameraDescription cameraDescription;
    if (VideoModel.cameras.isEmpty) {
      return;
    }
    if (controller != null) {
      await controller.dispose();
    }
    cameraIndex = cameraIndex == 0 ? 1 : 0;
    cameraDescription = VideoModel.cameras[cameraIndex];
    controller = CameraController(cameraDescription, videoResolution);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        Util.logError('camera error', controller.value.errorDescription);
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
    });
    videoTimer?.cancel();
    videoTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      videoAllSeconds++;
      videoSeconds = videoAllSeconds % 60;
      videoMinutes = videoAllSeconds ~/ 60;

      videoTimeStr =
          '${addZero(videoMinutes)}:${addZero(videoSeconds)}';
      setState(() {});

      if(videoAllSeconds >= 60 * 2){
        onStopButtonPressed();
      }
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted)
        setState(() {
          videoTimer?.cancel();
          videoAllSeconds = 0;
          videoSeconds = videoAllSeconds % 60;
          videoMinutes = videoAllSeconds ~/ 60;
          videoTimeStr =
              '${addZero(videoMinutes)}:${addZero(videoSeconds)}';
          setState(() {});
        });
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized || controller.value.isRecordingVideo) {
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_video_zz';
    final String fileName = timestamp();
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/$fileName.mp4';

    try {
      videoPath = filePath;
      videoFileName = fileName;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    VideoModel.path = videoPath;
    VideoModel.name = videoFileName;
    print('videopath, ${VideoModel.path}');
    UserModel.userName = "zz";
    Navigator.pushNamed(context, '/preview');
  }

  void _showCameraException(CameraException e) {
    Util.logError(e.code, e.description);
  }
}
