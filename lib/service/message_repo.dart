// lib/services/messages_repository.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MessagesRepository {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _roomRef(String roomId) => _db.ref('rooms/$roomId');

  // Stream list of messages (ordered by createdAt ascending)
  Stream<List<Map<String, dynamic>>> messagesStream(
    String roomId, {
    int limit = 200,
  }) {
    final ref = _roomRef(
      roomId,
    ).child('messages').orderByChild('createdAt').limitToLast(limit);
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        return <Map<String, dynamic>>[];
      }
      final map = Map<dynamic, dynamic>.from(value as Map);
      final list = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return m;
      }).toList();
      list.sort((a, b) {
        final A = a['createdAt'] is int
            ? a['createdAt'] as int
            : (a['createdAt'] as num).toInt();
        final B = b['createdAt'] is int
            ? b['createdAt'] as int
            : (b['createdAt'] as num).toInt();
        return A.compareTo(B);
      });
      return list;
    });
  }

  Future<void> sendMessage(String roomId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final ref = _roomRef(roomId).child('messages').push();
    await ref.set({
      'uid': user.uid,
      'text': text,
      'createdAt': ServerValue.timestamp,
      'type': 'text',
    });
  }

  // Presence
  Future<void> setOnline(String uid) async {
    final ref = _db.ref('presence/$uid');
    await ref.set({'online': true, 'lastSeen': ServerValue.timestamp});
    await ref.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> setOffline(String uid) async {
    await _db.ref('presence/$uid').set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  // Typing
  Future<void> setTyping(String roomId, String uid, bool typing) async {
    final ref = _db.ref('typing/$roomId/$uid');
    if (typing) {
      await ref.set(true);
      await ref.onDisconnect().remove();
    } else {
      await ref.remove();
    }
  }
}
