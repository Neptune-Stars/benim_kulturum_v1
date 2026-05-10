import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});


  Future<void> _deleteChat(String userId) async {
    final firestore = FirebaseFirestore.instance;


    var messages = await firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }


    await firestore.collection('support_chats').doc(userId).delete();
  }


  void _showDeleteDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Conversation?"),
        content: const Text("This will permanently remove all messages for this student. This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          TextButton(
              onPressed: () async {
                await _deleteChat(userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Conversation permanently deleted.")),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Support Messages"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: "Active", icon: Icon(Icons.chat_bubble_outline)),
              Tab(text: "Resolved", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatList(context, "active"),
            _buildChatList(context, "resolved"),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, String tabStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_chats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No support requests yet."));
        }



        final chats = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final currentStatus = data['status'] ?? 'active';
          return currentStatus == tabStatus;
        }).toList();

        if (chats.isEmpty) {
          return Center(child: Text("No $tabStatus chats."));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            var chat = chats[index].data() as Map<String, dynamic>;
            String userId = chats[index].id;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                chat['userName'] ?? "Student",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat['lastMessage'] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: tabStatus == "resolved"
                  ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, userId),
              )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminChatDetailScreen(
                        userId: userId,
                        userName: chat['userName'] ?? "Student"
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}