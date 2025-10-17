import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/constant/string_constant.dart';

class AgoraService {
  late final RtcEngine _engine;

  Future<void> initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableAudio();
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
  }) async {
    await _engine.joinChannel(
      token: "",
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  Future<void> destroy() async {
    await _engine.release();
  }

  RtcEngine get engine => _engine;
}
