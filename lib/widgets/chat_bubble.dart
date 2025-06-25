import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String username;
  final bool isMe;
  final dynamic timestamp;
  final String type; // 'text', 'image', 'file', 'video'
  final String mediaUrl;
  final bool isSeen;

  ChatBubble({
    required this.text,
    required this.username,
    required this.isMe,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl = '',
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    print("📨 Bubble -> text: $text | type: $type | timestamp: $timestamp");

    final timeStr = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp.toDate())
        : 'Sending...';

    Widget content;

    if (type == 'image') {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          width: 200,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 200,
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    } else if (type == 'file' || type == 'video') {
      content = GestureDetector(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(mediaUrl))) {
            await launchUrl(Uri.parse(mediaUrl), mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'video' ? Icons.videocam : Icons.insert_drive_file,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey[700],
              radius: 18,
              child: Text(
                username[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: type == 'text' ? EdgeInsets.all(10) : EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple : Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: isMe ? Radius.circular(14) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 6),
                      child: Text(
                        username,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SizedBox(height: 4),
                  content,
                  SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 6),
        ],
      ),
    );
  }
}
