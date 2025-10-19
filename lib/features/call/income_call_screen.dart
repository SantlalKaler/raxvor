/*
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String channelName;
  final String callType; // "audio" or "video"
  final String callDocId; // Firestore document ID

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.channelName,
    required this.callType,
    required this.callDocId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    // Stop ringtone
    _audioPlayer.stop();

    // Update Firestore status
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callDocId)
        .update({'status': 'accepted'});

    // Navigate to Agora Call Screen
    */
/*    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraCallScreen(
          channelName: widget.channelName,
          callType: widget.callType,
        ),
      ),
    );*/ /*

  }

  Future<void> _rejectCall() async {
    _audioPlayer.stop();

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callDocId)
        .update({'status': 'rejected'});

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade600,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                widget.callerName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.callerName} is calling...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _rejectCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
                ElevatedButton(
                  onPressed: _acceptCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
