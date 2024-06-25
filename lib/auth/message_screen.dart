import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messaging/auth/chat_screen.dart';
import 'package:messaging/auth/add_user_screen.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddUserScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (ctx, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          final chats = chatSnapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (ctx, index) {
              final chatData = chats[index].data();
              final chatId = chats[index].id;
              final otherUserId = (chatData['participants'] as List<dynamic>)
                  .firstWhere((id) => id != currentUser.uid);

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (ctx, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data?.data();
                  final phoneNumber =
                      userData?['phoneNumber'] ?? 'Unknown User';
                  final imageUrl = userData?['image_url'] ?? '';

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (ctx, messageSnapshot) {
                      String lastMessage = 'No messages yet';
                      if (messageSnapshot.hasData &&
                          messageSnapshot.data!.docs.isNotEmpty) {
                        lastMessage = messageSnapshot.data!.docs.first['text'];
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                        title: Text(phoneNumber),
                        subtitle: Text(lastMessage),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userId: otherUserId,
                                phoneNumber: phoneNumber,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
