// lib/features/chat/chatroom_controller.dart  (or wherever your ChatController lives)
import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raxvor/app/constants.dart';

import '../../app/constant/string_constant.dart';
import '../../service/message_repo.dart';

final chatControllerProvider =
    StateNotifierProvider<
      ChatController,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => ChatController(ref));

class ChatController
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  final MessagesRepository _repo;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _currentRoomId;
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;

  ChatController(this._ref)
    : _repo = MessagesRepository(),
      super(const AsyncValue.data([]));

  ///--------------- Call
  Future<void> initAgora(String appId, String token, String channelName) async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: agoraAppId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          printValue('Local user joined channel: ${connection.localUid}');
          _isJoined = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          printValue('Remote user joined: $remoteUid');
          _remoteUid = remoteUid;
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              printValue('Remote user left: $remoteUid');
              _remoteUid = null;
            },
      ),
    );

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _isJoined = false;
      _remoteUid = null;
    }
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
