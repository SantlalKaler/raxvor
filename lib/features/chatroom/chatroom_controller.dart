// lib/features/chat/chatroom_controller.dart  (or wherever your ChatController lives)
import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:raxvor/app/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constant/string_constant.dart';
import '../../service/call_repo.dart';
import '../../service/message_repo.dart';

final chatControllerProvider =
    StateNotifierProvider<
      ChatController,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => ChatController(ref));

final muteProvider = StateProvider<bool>((ref) => false);
final speakerProvider = StateProvider<bool>((ref) => false);
final timerProvider = StateProvider<Duration>((ref) => Duration.zero);
final videoProvider = StateProvider<bool>((ref) => false);

class ChatController
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  final MessagesRepository _repo;
  bool isJoined;
  final CallRepository _callRepo;
  Duration callDuration = Duration.zero;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String? _currentRoomId;
  RtcEngine? engine;
  int? remoteUid;

  ChatController(this._ref)
    : _repo = MessagesRepository(),
      _callRepo = CallRepository(),
      isJoined = false,
      super(const AsyncValue.data([]));

  Timer? _callTimer;

  void startTimer() {
    callDuration = Duration.zero;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration += const Duration(seconds: 1);
      _ref.read(timerProvider.notifier).state = callDuration;
    });
  }

  void stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _ref.read(timerProvider.notifier).state = Duration.zero;
  }

  ///--------------- Call
  Future<void> initAgora(String channelName, {bool isVideo = false}) async {
    try {
      if (isVideo) {
        await [Permission.microphone, Permission.camera].request();
      } else {
        await [Permission.microphone].request();
      }

      engine = createAgoraRtcEngine();
      await engine!.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      printValue("Calling");

      if (isVideo) {
        await engine!.enableVideo();
        await engine!.startPreview();
        _ref.read(videoProvider.notifier).state = true;
      } else {
        await engine!.disableVideo();
      }

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            printValue('Local user joined channel: ${connection.localUid}');
            this.isJoined = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            printValue('Remote user joined: $remoteUid');
            startTimer();
            this.remoteUid = remoteUid;
          },
          onError: (err, msg) => printValue("Error in calling $err\n$msg"),
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                printValue('Remote user left: $remoteUid');
                this.remoteUid = null;
                leaveChannel();
              },
        ),
      );

      await engine!.joinChannel(
        token: agoraToken,
        channelId: tempChannel,
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideo,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } on Exception catch (e) {
      printValue("Error in init agora : ${e.toString()}");
    }
  }

  Future<void> leaveChannel() async {
    if (engine != null) {
      await engine!.leaveChannel();
      await engine!.release();
      isJoined = false;
      remoteUid = null;
      _ref.read(videoProvider.notifier).state = false;
      stopTimer();
      _ref.read(muteProvider.notifier).state = false;
      printValue("Call end");
    }
  }

  void toggleMute() {
    final currentMute = _ref.read(muteProvider);
    final newMute = !currentMute;

    _ref.read(muteProvider.notifier).state = newMute;

    engine?.muteLocalAudioStream(newMute);
    printValue("Mic is ${newMute ? "muted" : "unmuted"}");
  }

  Future<void> toggleSpeaker() async {
    final currentSpeaker = _ref.read(speakerProvider);
    var isSpeakerOn = !currentSpeaker;
    _ref.read(speakerProvider.notifier).state = isSpeakerOn;
    await engine?.setEnableSpeakerphone(isSpeakerOn);
  }

  Future<void> toggleVideo() async {
    final current = _ref.read(videoProvider);
    final newVideo = !current;
    _ref.read(videoProvider.notifier).state = newVideo;

    if (newVideo) {
      await engine?.enableVideo();
      await engine?.startPreview();
    } else {
      await engine?.disableVideo();
      await engine?.stopPreview();
    }
    printValue("Video is ${newVideo ? "enabled" : "disabled"}");
  }

  Future<String?> getFCMToken(String uid) async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .from(supabaseUserTable)
          .select()
          .eq('uid', uid)
          .single();
      printValue("User from supabase : $data");
      return data['fcm_token'];
    } catch (e, st) {
      printValue("Error in getting FCM token : $e");
    }
    return null;
  }

  Future<void> startCall(String receiverUid) async {
    final current = FirebaseAuth.instance.currentUser!;
    final channel = "call_${current.uid}_$receiverUid";

    final fcmToken = await getFCMToken(receiverUid);

    final token = fcmToken;
    if (token == null) {
      printValue("Receiver FCM token not found");
      return;
    }

    final callData = {
      'callerId': current.uid,
      'receiverId': receiverUid,
      'channelName': channel,
      'status': 'ringing',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    printValue("Update firestore call strtus");

    await _callRepo.startCall(callData);

    await sendPushNotification(
      token: fcmToken ?? "",
      callerName: receiverUid,
      channelName: tempChannel,
    );
  }

  Future<void> sendPushNotification({
    required String token,
    required String callerName,
    required String channelName,
  }) async {
    const String serverKey =
        'YOUR_FIREBASE_SERVER_KEY_HERE'; // Replace with real key

    final body = {
      'to': token,
      'notification': {
        'title': 'Incoming Call',
        'body': '$callerName is calling you',
        'android_channel_id': 'calls',
        'priority': 'high',
      },
      'data': {
        'type': 'incoming_call',
        'callerName': callerName,
        'channelName': channelName,
      },
    };

    try {
      final res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(body),
      );

      printValue('FCM response: ${res.statusCode} => ${res.body}');
    } catch (e) {
      printValue('Error sending FCM: $e');
    }
  }

  Stream listenIncomingCalls() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _callRepo.listenIncomingCalls(uid);
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _callRepo.updateCallStatus(callId, status);
  }

  /// --------------- Chat
  void subscribeToRoom(String roomId) {
    _currentRoomId = roomId;
    _sub?.cancel();

    state = const AsyncValue.loading();

    _sub = _repo.messagesStream(roomId).listen((messages) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final formatted = messages.map((msg) {
        return {...msg, 'isMe': msg['uid'] == currentUid};
      }).toList();

      printValue("Message are : $formatted");

      if (mounted) {
        state = AsyncValue.data(formatted);
      }
    });
  }

  void unsubscribe() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> sendMessage(String receiverUid, String text) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = getRoomId(currentUid!, receiverUid);
    await _repo.sendMessage(roomId, text);
  }

  Future<void> setPresenceOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _repo.setOnline(uid);
  }

  Future<void> setPresenceOffline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _repo.setOffline(uid);
  }

  Future<void> setTyping(String receiverUid, bool typing) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = getRoomId(currentUid!, receiverUid);
    await _repo.setTyping(roomId, currentUid, typing);
  }

  String getRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
