import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/chat_screen.dart';


class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  String _searchQuery = '';
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> _buildUserStream(String query) {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('username')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userStream = _searchQuery.isNotEmpty ? _buildUserStream(_searchQuery) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search by username',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(child: Text('Start typing to search users', style: GoogleFonts.poppins()))
                : StreamBuilder<QuerySnapshot>(
              stream: userStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found', style: GoogleFonts.poppins()));
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserUid)
                    .toList();

                if (users.isEmpty) {
                  return Center(child: Text('No other users found', style: GoogleFonts.poppins()));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          user['username'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user['username'], style: GoogleFonts.poppins()),
                      onTap: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final currentUid = currentUser?.uid;
                        final recipientUid = user.id;
                        final recipientUsername = user['username'];

                        if (currentUid == null) return;

                        final chatId = currentUid.hashCode <= recipientUid.hashCode
                            ? '${currentUid}_$recipientUid'
                            : '${recipientUid}_$currentUid';

                        // Fetch current user's username
                        final currentUserDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUid)
                            .get();

                        final senderUsername = currentUserDoc['username'] ?? 'You';

                        // Create chat doc if it doesn't exist
                        final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
                        final chatSnapshot = await chatDoc.get();

                        if (!chatSnapshot.exists) {
                          await chatDoc.set({
                            'participants': [currentUid, recipientUid],
                            'usernames': [senderUsername, recipientUsername],
                            'createdAt': Timestamp.now(),
                          });
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              recipientUid: recipientUid,
                              recipientUsername: recipientUsername,
                              senderUsername: senderUsername,
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
