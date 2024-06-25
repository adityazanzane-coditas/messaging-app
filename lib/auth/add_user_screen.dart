import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messaging/auth/chat_screen.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: const Text('Add Person'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (ctx, usersSnapshot) {
                if (usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!usersSnapshot.hasData ||
                    usersSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = usersSnapshot.data!.docs;
                final filteredUsers = users.where((user) {
                  final userData = user.data() as Map<String, dynamic>;
                  final phoneNumber =
                      userData['phoneNumber']?.toString().toLowerCase() ?? '';
                  return phoneNumber.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, index) {
                    final userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    final userId = filteredUsers[index].id;

                    if (userId == currentUser.uid) {
                      return Container();
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(userData['image_url'] ?? ''),
                      ),
                      title: Text(userData['phoneNumber'] ?? 'Unknown'),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              userId: userId,
                              phoneNumber: userData['phoneNumber'] ?? 'Unknown',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
