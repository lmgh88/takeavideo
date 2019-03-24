import 'package:event_bus/event_bus.dart';

EventBus eventBus = new EventBus();

///上传视频事件
class UploadVideoEvent {
  int sent, total;

  UploadVideoEvent(this.sent, this.total);
}
