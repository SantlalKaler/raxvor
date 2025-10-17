import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raxvor/app/constants.dart';

import '../../app/constant/string_constant.dart';
import '../../app/images.dart';
import 'chatroom_controller.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.uId,
    required this.userName,
    required this.profileImage,
  });
  final String uId;
  final String userName;
  final String profileImage;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();

  RtcEngine? _engine;
  bool _inCall = false;
  bool _muted = false;
  int _localUid = 0;
  Set<int> _remoteUids = {};

  @override
  void initState() {
    super.initState();

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final roomId = getRoomId(currentUid, widget.uId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      printValue("📦 Subscribing to roomId: $roomId");
      ref.read(chatControllerProvider.notifier).subscribeToRoom(roomId);
      ref.read(chatControllerProvider.notifier).setPresenceOnline();
    });
  }

  Future<void> _startAudioCall(String channelName) async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    // 2) create engine
    _engine ??= createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _inCall = true;
          });
          printValue('Agora: joined channel ${connection.channelId}');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
          });
          printValue('Agora: remote uid joined $remoteUid');
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
          });
          printValue('Agora: remote uid left $remoteUid');
        },
      ),
    );

    await _engine!.enableAudio();

    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: _localUid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _endAudioCall() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (e) {
        print('Error leaving channel: $e');
      } finally {
        setState(() {
          _engine = null;
          _inCall = false;
          _muted = false;
          _remoteUids.clear();
        });
      }
    }
  }

  void _toggleMute() {
    if (_engine == null) return;
    _muted = !_muted;
    _engine!.muteLocalAudioStream(_muted);
    setState(() {});
  }

  String getRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  void dispose() {
    ref.read(chatControllerProvider.notifier).setPresenceOffline();
    ref.read(chatControllerProvider.notifier).unsubscribe();
    messageController.dispose();

    _endAudioCall();
    super.dispose();
  }

  void _showInCallSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'In call with ${widget.userName}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    color: _muted ? Colors.white : Colors.deepPurple,
                    iconSize: 28,
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await _endAudioCall();
                      Navigator.pop(context); // close sheet
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Participants: ${_remoteUids.length + 1}'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: AssetImage(ImageConst.user) as ImageProvider,
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: TextStyle(fontSize: 16)),
                if (_inCall)
                  Text(
                    'In call • ${_remoteUids.length + 1} connected',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final currentUid = FirebaseAuth.instance.currentUser!.uid;
              final roomId = getRoomId(currentUid, widget.uId);

              if (!_inCall) {
                // start call
                await _startAudioCall(roomId);
                // Optionally, open a bottom sheet showing call UI
                _showInCallSheet();
              } else {
                // end call
                await _endAudioCall();
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // optional close sheet
              }
            },
            icon: Icon(_inCall ? Icons.call_end : Icons.call),
            color: _inCall ? Colors.red : Colors.white,
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              data: (messages) {
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return Align(
                      alignment: msg['isMe']
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: msg['isMe']
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: msg['isMe'] ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (v) {
                      ref
                          .read(chatControllerProvider.notifier)
                          .setTyping(widget.uId, v.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      final text = messageController.text.trim();
                      if (text.isNotEmpty) {
                        await ref
                            .read(chatControllerProvider.notifier)
                            .sendMessage(widget.uId, text);
                        messageController.clear();
                        ref
                            .read(chatControllerProvider.notifier)
                            .setTyping(widget.uId, false);
                      }
                      messageController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
