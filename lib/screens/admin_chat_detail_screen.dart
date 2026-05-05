import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendAdminMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();

    //  Mesajı admin olarak ekle
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'text': text,
      'sender': 'admin', // Önemli: Admin olduğu belirtiliyor
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('support_chats').doc(widget.userId).update({
      'lastMessage': "Support: $text",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.userName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == 'admin';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Type a reply..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendAdminMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}