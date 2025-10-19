import 'package:cloud_firestore/cloud_firestore.dart';

class CallRepository {
  final _firestore = FirebaseFirestore.instance;

  // Listen for new incoming calls to this user
  Stream<QuerySnapshot<Map<String, dynamic>>> listenIncomingCalls(String uid) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  // Start a new call record
  Future<void> startCall(Map<String, dynamic> callData) async {
    await _firestore.collection('calls').add(callData);
  }

  // Update call status (accepted, rejected, ended)
  Future<void> updateCallStatus(String callId, String status) async {
    await _firestore.collection('calls').doc(callId).update({'status': status});
  }

  // End a call
  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }
}
