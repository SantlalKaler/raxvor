import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raxvor/app/app_routes.dart';

import '../../app/images.dart';
import 'chat_list_controller.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final chatListState = ref.watch(chatListControllerProvider);

    return Scaffold(
      body: chatListState.when(
        data: (users) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: ListTile(
                  tileColor: Colors.grey.withValues(alpha: 0.1),
                  onTap: () {
                    Map<String, dynamic> data = {
                      "uId": user['uid'],
                      "username": user['name'],
                      "profile_image": user['profile_image'] ?? "",
                      "online": user['online'],
                      "lastSeen": user['lastSeen'],
                    };
                    context.push(AppRoutes.chatroom, extra: data);
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: user['profile_image'] != null
                            ? NetworkImage(user['profile_image'])
                            : AssetImage(ImageConst.user) as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: user['online'] == true
                              ? Colors.green
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    user['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user['lastMessage'] ?? ""),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user['time'] ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      /*  if (user['unread'] > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user['unread'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),*/
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text('Something went wrong: ${err.toString()}')),
      ),
    );
  }
}
