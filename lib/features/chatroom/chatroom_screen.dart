import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:raxvor/features/home/chat_list_controller.dart';

import '../../app/constant/string_constant.dart';
import '../../app/images.dart';
import 'chatroom_controller.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.uId,
    required this.userName,
    required this.profileImage,
    required this.lastSeen,
    required this.online,
  });
  final String uId;
  final String userName;
  final String profileImage;
  final int lastSeen;
  final bool online;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final roomId = getRoomId(currentUid, widget.uId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).subscribeToRoom(roomId);
      ref.read(chatControllerProvider.notifier).setPresenceOnline();
    });
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
    super.dispose();
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
        title: Consumer(
          builder: (context, ref, child) {
            final _ = ref.watch(chatControllerProvider.notifier);
            final _ = ref.watch(chatControllerProvider);
            return Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: widget.profileImage != ""
                      ? NetworkImage(widget.profileImage)
                      : AssetImage(ImageConst.user) as ImageProvider,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName, style: TextStyle(fontSize: 16)),

                    Text(
                      widget.online
                          ? "Online"
                          : DateFormat('dd-MMM-yyyy hh:mm a')
                                .format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    widget.lastSeen,
                                  ),
                                )
                                .toString(),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final currentUid = FirebaseAuth.instance.currentUser!.uid;
              final roomId = getRoomId(currentUid, widget.uId);

              if (!ref.read(chatControllerProvider.notifier).isJoined) {
                showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                await ref
                    .read(chatControllerProvider.notifier)
                    .initAgora(roomId);
                context.pop();
                showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  builder: (_) {
                    return Consumer(
                      builder: (context, ref, child) {
                        return InCallBottomSheet(userName: widget.userName);
                      },
                    );
                  },
                );
                /* if (ref.read(chatControllerProvider.notifier).isJoined) {
                  showModalBottomSheet(
                    context: context,
                    isDismissible: false,
                    builder: (_) {
                      return Consumer(
                        builder: (context, ref, child) {
                          return InCallBottomSheet(userName: widget.userName);
                        },
                      );
                    },
                  );
                }
                else {
                  showModalBottomSheet(
                    context: context,
                    isDismissible: false,
                    builder: (_) {
                      return Consumer(
                        builder: (context, ref, child) {
                          return Padding(
                            padding: EdgeInsetsGeometry.all(16),
                            child: Column(
                              children: [
                                Text(
                                  "Unable to connect with ${widget.userName}",
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        context.pop();
                                      },
                                      child: Text("Ok"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }*/
                /* await ref
                    .read(chatControllerProvider.notifier)
                    .startCall(widget.uId);*/
              } else {
                await ref.read(chatControllerProvider.notifier).leaveChannel();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: Icon(Icons.call),
            color: Colors.black87,
          ),
          IconButton(
            onPressed: () async {
              final currentUid = FirebaseAuth.instance.currentUser!.uid;
              final roomId = getRoomId(currentUid, widget.uId);

              if (!ref.read(chatControllerProvider.notifier).isJoined) {
                showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  builder: (_) => const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(),
                  ),
                );

                await ref
                    .read(chatControllerProvider.notifier)
                    .initAgora(roomId, isVideo: true);
                context.pop();

                showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  isScrollControlled: true,
                  builder: (_) => const VideoCallBottomSheet(),
                );
              } else {
                await ref.read(chatControllerProvider.notifier).leaveChannel();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: Icon(Icons.video_call),
          ),
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
                        ref
                            .read(chatListControllerProvider.notifier)
                            .loadUsersWithLastMessages();
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

class InCallBottomSheet extends ConsumerStatefulWidget {
  const InCallBottomSheet({super.key, required this.userName});
  final String userName;

  @override
  ConsumerState<InCallBottomSheet> createState() => _InCallBottomSheetState();
}

class _InCallBottomSheetState extends ConsumerState<InCallBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final isMuted = ref.watch(muteProvider);
    final isSpeaker = ref.watch(speakerProvider);
    var timer = ref.watch(timerProvider);

    String _formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(timer), style: const TextStyle(fontSize: 12)),
          Text(
            'In call with ${widget.userName}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(chatControllerProvider.notifier).toggleMute(),
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                iconSize: 28,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () =>
                    ref.read(chatControllerProvider.notifier).toggleSpeaker(),
                icon: Icon(isSpeaker ? Icons.volume_up : Icons.volume_down),
                iconSize: 28,
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await ref
                      .read(chatControllerProvider.notifier)
                      .leaveChannel();
                  context.pop();
                },
                child: const Text(
                  'Leave',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          /* const SizedBox(height: 8),
              Text(
                'Participants: ${ref.read(chatControllerProvider.notifier).remoteUid}',
              ),*/
        ],
      ),
    );
  }
}

class VideoCallBottomSheet extends ConsumerWidget {
  const VideoCallBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(muteProvider);
    final isSpeaker = ref.watch(speakerProvider);
    final isVideo = ref.watch(videoProvider);
    final timer = ref.watch(timerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final remoteUid = controller.remoteUid;

    String _formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    return SafeArea(
      child: Column(
        children: [
          Text(_formatDuration(timer), style: const TextStyle(fontSize: 12)),
          Expanded(
            child: Stack(
              children: [
                if (remoteUid != null)
                  AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: controller.engine!,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: tempChannel),
                    ),
                  )
                else
                  const Center(child: Text("Waiting for remote user...")),

                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: controller.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(chatControllerProvider.notifier).toggleMute(),
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(chatControllerProvider.notifier).toggleSpeaker(),
                icon: Icon(isSpeaker ? Icons.volume_up : Icons.volume_down),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(chatControllerProvider.notifier).toggleVideo(),
                icon: Icon(isVideo ? Icons.videocam : Icons.videocam_off),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await controller.leaveChannel();
                  Navigator.pop(context);
                },
                child: const Text('End', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
