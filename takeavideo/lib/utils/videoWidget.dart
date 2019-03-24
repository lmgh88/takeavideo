import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

typedef Widget VideoWidgetBuilder(BuildContext context, VideoPlayerController controller);

abstract class PlayerLifeCycle extends StatefulWidget{
  final String dataSource;
  final VideoWidgetBuilder childBuilder;
  PlayerLifeCycle(this.dataSource,this.childBuilder);
}