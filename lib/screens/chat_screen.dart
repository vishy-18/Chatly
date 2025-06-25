import 'package:chatly/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientUid;
  final String recipientUsername;
  final String senderUsername; // 👈 ADD THIS

  const ChatScreen({
    required this.chatId,
    required this.recipientUid,
    required this.recipientUsername,
    required this.senderUsername, // 👈 AND THIS
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;

  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    final user = _authService.currentUser;
    final text = _controller.text.trim();

    if (text.isEmpty || user == null) return;

    final timestamp = Timestamp.now();

    final chatRef = _firestore.collection('chats').doc(widget.chatId);
    final messagesRef = chatRef.collection('messages');

    final message = {
      'senderUid': user.uid,
      'senderUsername': widget.senderUsername, // ✅ FIXED
      'text': text,
      'timestamp': timestamp,
    };

    try {
      await chatRef.set({
        'participants': [user.uid, widget.recipientUid],
        'usernames': [widget.senderUsername, widget.recipientUsername],
        'lastMessage': text,
        'timestamp': timestamp,
        'unread.${widget.recipientUid}': FieldValue.increment(1),
        'typing.${user.uid}': false,
      }, SetOptions(merge: true));

      await messagesRef.add(message);

      _controller.clear();
      if (isTyping) {
        isTyping = false;
        _updateTyping(false);
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  void _updateTyping(bool value) async {
    final user = _authService.currentUser;
    if (user == null || isTyping == value) return;

    setState(() => isTyping = value);
    await _firestore.collection('chats').doc(widget.chatId).set(
      {'typing.${user.uid}': value},
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientUsername, style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isMe = data['senderUid'] == user?.uid;
                    final messageText = data['text'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurple : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          messageText,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        _updateTyping(true);
                      } else {
                        _updateTyping(false);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
