import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Future<Map<String, dynamic>?> _userFuture;
  String? _selectedFamily;
  List<Map<String, dynamic>> _families = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
  }

  Future<Map<String, dynamic>?> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();
      if (doc.exists) {
        final userData = doc.data();
        await _fetchUserFamilies(userData?['families'] as List<dynamic>?);
        return userData;
      }
    }
    return null;
  }

  Future<void> _fetchUserFamilies(List<dynamic>? families) async {
    if (families != null) {
      List<Map<String, dynamic>> userFamilies = [];
      for (String familyCode in families) {
        final familyDoc = await FirebaseFirestore.instance
            .collection('families')
            .doc(familyCode)
            .get();
        if (familyDoc.exists) {
          families.add({
            'familyCode': familyCode,
            ...familyDoc.data()!,
          });
        }
      }
      setState(() {
        _families = userFamilies;
        if (_families.isNotEmpty) {
          _selectedFamily = _families.first['familyCode'];
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    try {
      final user = await _userFuture;
      if (user != null && _selectedFamily != null) {
        final message = _messageController.text.trim();
        if (message.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('families')
              .doc(_selectedFamily)
              .collection('messages')
              .add({
            'uid': _currentUserId,
            'email': user['email'] ?? '',
            'displayName': user['displayName'] ?? '',
            'photoURL': user['photoURL'] ?? '',
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
          });
          _messageController.clear();
        }
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Widget _buildMessage(Map<String, dynamic> messageData, bool isSender) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSender ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isSender ? const Radius.circular(12) : Radius.zero,
            bottomRight: isSender ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSender)
              Text(
                messageData['displayName'] ?? 'No name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 5),
            Text(
              messageData['message'] ?? 'No message',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Chat'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Select Family:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFamily,
                    items: _families
                        .map((family) => DropdownMenuItem<String>(
                              value: family['familyCode'],
                              child: Text(
                                  family['familyName'] ?? 'Unnamed Family'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFamily = value;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedFamily == null
                ? const Center(child: Text('No family selected.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('families')
                        .doc(_selectedFamily)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }
                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              messages[index].data() as Map<String, dynamic>;
                          final isSender = message['uid'] == _currentUserId;
                          return _buildMessage(message, isSender);
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
