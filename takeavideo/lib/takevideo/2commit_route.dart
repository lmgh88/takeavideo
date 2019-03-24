import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../model/video_model.dart';
import '../model/user_model.dart';
import '../utils/util.dart';
import '../bus/bus.dart';

class CommitRoute extends StatefulWidget {
  @override
  _CommitRouteState createState() => _CommitRouteState();
}

class _CommitRouteState extends State<CommitRoute> {
  var titleController = new TextEditingController();
  var descController = new TextEditingController();
  var hintTips = new TextStyle(fontSize: 15.0, color: Colors.black);
  String videoPath = '';
  String videoFileName = '';
  bool uploading = false;
  Timer timer;

  String uploadInter = 'http://www.abc.com/';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _doUpload(BuildContext context) async {
    if (uploading == true) {
      return;
    }
    await _uploadVideoFile(context);
  }

  Future<Null> _uploadVideoFile(BuildContext context) async {
    var dio = new Dio(Options(connectTimeout: 900000, receiveTimeout: 900000));
    String videoTitle = titleController.text;
    String videoDesc = descController.text;
    if (videoTitle == '') {
      Util.showToast('请输入标题');
    } else if (videoDesc == '') {
      Util.showToast('请输入描述');
    } else {
      File file = File(videoPath);
      int fileLength = await file.length();
      FormData formData = FormData.from({
        "video_title": videoTitle,
        "video_description": videoDesc,
        "video_source": UserModel.userName,
        "video_file": UploadFileInfo(file, videoFileName),
      });
      uploading = true;
      print('FileLength: ${fileLength / 1024 / 1024} MB');
      int startTime = DateTime.now().millisecondsSinceEpoch;
      print('---上传中---');

      showDialog<Null>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            String text = '上传中，请稍候...';
            return StatefulBuilder(
              builder: (context, state) {
                return LoadingDialog(
                  text: text,
                );
              },
            );
          });

      timer = Timer(Duration(milliseconds: 200), () async {
        try {
          Response<Object> response = await dio.post(uploadInter,
              data: formData, onUploadProgress: (int sent, int total) {
            eventBus.fire(new UploadVideoEvent(sent, total));
          });
          Map<String, dynamic> res = jsonDecode(response.data);

          uploading = false;
          print('video_id: ${res['data']['video_id']}');
          print('video_url: ${res['data']['video_url']}');
          Navigator.pop(context);
          Util.showInSnackBar(_scaffoldKey, '上传成功!');
          print(
              '---上传结束--- ，上传耗时：${(DateTime.now().millisecondsSinceEpoch - startTime) / 1000} s');
          file.delete(recursive: false);
          timer = Timer(Duration(milliseconds: 1500), () {
            Navigator.popUntil(context, ModalRoute.withName('/camera'));
          });
        } on DioError catch (error, stackTrace) {
          uploading = false;
          Navigator.pop(context);
          Util.logError('', error.message);
          Util.showInSnackBar(_scaffoldKey, '错误：${error.message}');
        }
      });
    }
  }

  @override
  void initState() {
    videoPath = VideoModel.path;
    videoFileName = VideoModel.name + '.mp4';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('上传'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 5.0),
            child: TextField(
              style: hintTips,
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: '请输入标题',
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54))),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 5.0),
            child: TextField(
              style: hintTips,
              controller: descController,
              decoration: InputDecoration(
                  hintText: '请输入描述',
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54))),
            ),
          ),
          Container(
            width: 360.0,
            margin: EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 0.0),
            padding: EdgeInsets.fromLTRB(30.0, 4.0, 30.0, 4.0),
            child: Card(
              color: Colors.green,
              elevation: 6.0,
              child: FlatButton(
                  onPressed: () {
                    _doUpload(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      '上传',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  )),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class LoadingDialog extends StatefulWidget {
  final String text;

  LoadingDialog({Key key, this.text}) : super(key: key);

  @override
  _LoadingDialogState createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  String text;
  int sent, total;
  String uploadPercent = '';

  @override
  void initState() {
    text = widget.text;
    eventBus.on<UploadVideoEvent>().listen((event) {
      print('sent: ${event.sent} , total: ${event.total}');
      sent = event.sent;
      total = event.total;
      uploadPercent = '${(sent / total * 100).toStringAsFixed(0)}%';
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      type: MaterialType.transparency,
      child: new Center(
        child: new SizedBox(
          width: 120.0,
          height: 120.0,
          child: new Container(
            decoration: ShapeDecoration(
              color: Color(0xffffffff),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
              ),
            ),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new CircularProgressIndicator(),
                new Padding(
                  padding: const EdgeInsets.only(
                    top: 20.0,
                  ),
                  child: new Text(
                    sent == null ? text : uploadPercent,
                    style: new TextStyle(fontSize: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
