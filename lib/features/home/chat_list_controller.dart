import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatListControllerProvider =
    StateNotifierProvider<
      ChatListController,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => ChatListController());

class ChatListController
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  ChatListController() : super(const AsyncValue.data([])) {
    loadUsersWithLastMessages();
  }

  final supabase = Supabase.instance.client;

  Future<void> loadUsersWithLastMessages() async {
    try {
      state = const AsyncValue.loading();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');
      final uid = currentUser.uid;

      final response = await supabase
          .from('user')
          .select()
          .neq('uid', uid)
          .order('name');

      final users = List<Map<String, dynamic>>.from(response);

      String getRoomId(String uid1, String uid2) {
        final sorted = [uid1, uid2]..sort();
        return '${sorted[0]}_${sorted[1]}';
      }

      final updatedUsers = await Future.wait(
        users.map((user) async {
          final otherUid = user['uid'];
          final roomId = getRoomId(uid, otherUid);

          final _db = FirebaseDatabase.instance;
          final lastMsgSnap = await _db
              .ref('rooms/$roomId/messages')
              .orderByChild('createdAt')
              .limitToLast(1)
              .get();

          final onlineDb = await _db.ref('presence/$uid').get();

          String? lastMessage;
          String? time;
          int? lastSeen;
          bool online = false;

          if (onlineDb.exists && onlineDb.value != null) {
            final dataMap = Map<String, dynamic>.from(
              onlineDb.value as Map<Object?, Object?>,
            );
            online = dataMap['online'] == "true" ? true : false;
            lastSeen = dataMap['lastSeen'];
          }

          if (lastMsgSnap.exists && lastMsgSnap.value != null) {
            final dataMap = Map<String, dynamic>.from(
              lastMsgSnap.value as Map<Object?, Object?>,
            );
            final last = dataMap.values.first as Map;
            lastMessage = last['text'];
            final timestamp = last['createdAt'];
            if (timestamp != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
              time =
                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }
          }

          return {
            ...user,
            'lastMessage': lastMessage ?? '',
            'time': time ?? '',
            'online': online,
            'lastSeen': lastSeen ?? "",
          };
        }),
      );

      state = AsyncValue.data(updatedUsers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadUsers() async {
    try {
      state = const AsyncValue.loading();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      final uid = currentUser.uid;
      final response = await supabase
          .from('user')
          .select()
          .neq('uid', uid)
          .order('name');

      final users = List<Map<String, dynamic>>.from(response);
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
