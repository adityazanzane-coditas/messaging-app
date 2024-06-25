import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  final String receiverId;

  const NewMessage({super.key, required this.receiverId});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    FocusScope.of(context).unfocus();
    _messageController.clear();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist');
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data is null');
      }

      final chatRoomId = getChatRoomId(user.uid, widget.receiverId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': enteredMessage,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'phoneNumber': userData['phoneNumber'] ?? 'Unknown User',
        'userImage': userData['image_url'] ?? '',
        'isRead': false,
      });

      await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
        'lastMessage': enteredMessage,
        'lastMessageTime': Timestamp.now(),
        'participants': [user.uid, widget.receiverId],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '$user1-$user2';
    } else {
      return '$user2-$user1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              minLines: 1,
              maxLines: null,
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                hintText: 'Type a message',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        const BorderSide(color: Colors.black, width: 12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(color: Colors.black)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              ),
            ),
          ),
          IconButton(
            onPressed: _isSending ? null : _submitMessage,
            icon: _isSending
                ? const Icon(Icons.send)
                : const Icon(Icons.send_rounded),
          )
        ],
      ),
    );
  }
}
