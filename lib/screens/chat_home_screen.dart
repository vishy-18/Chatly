import 'package:chatly/screens/chat_screen.dart';
import 'package:chatly/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final user = AuthService().currentUser;
  String currentUsername = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  Future<void> _loadCurrentUsername() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      currentUsername = doc['username'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Chatly", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              ),
            );
          }

          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(child: Text("No chats yet", style: GoogleFonts.poppins()));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final usernames = List<String>.from(data['usernames'] ?? []);
              final participantList = List<String>.from(data['participants'] ?? []);

              final recipientUsername = (usernames.length > 1)
                  ? usernames.firstWhere((name) => name != currentUsername, orElse: () => usernames.first)
                  : usernames.isNotEmpty ? usernames.first : "Unknown";

              final recipientUid = participantList.firstWhere(
                    (uid) => uid != user!.uid,
                orElse: () => '',
              );

              final lastMessage = data['lastMessage'] ?? '';
              final timestamp = data['lastTimestamp'] as Timestamp?;

              String formattedTime = '';
              if (timestamp != null) {
                final now = DateTime.now();
                final messageDate = timestamp.toDate();
                if (now.difference(messageDate).inDays == 0) {
                  formattedTime = DateFormat('hh:mm a').format(messageDate);
                } else {
                  formattedTime = DateFormat('MMM d').format(messageDate);
                }
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage("https://api.dicebear.com/7.x/initials/svg?seed=$recipientUsername"),
                ),
                title: Text(recipientUsername, style: GoogleFonts.poppins()),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: timestamp != null
                    ? Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
                    : null,
                onTap: () async {
                  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                    'unread': {user!.uid: 0},
                    'typing': {user!.uid: false},
                  }, SetOptions(merge: true));

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        recipientUid: recipientUid,
                        recipientUsername: recipientUsername,
                        senderUsername: currentUsername,
                      ),
                    ),
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
