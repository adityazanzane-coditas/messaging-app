import 'package:flutter/material.dart';
import 'package:messaging/widgets/chat_messages.dart';
import 'package:messaging/widgets/new_message.dart';

class ChatScreen extends StatelessWidget {
  final String userId;
  final String phoneNumber;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(phoneNumber),
      ),
      body: Column(
        children: [
          Expanded(child: ChatMessages(userId: userId)),
          NewMessage(receiverId: userId),
        ],
      ),
    );
  }
}