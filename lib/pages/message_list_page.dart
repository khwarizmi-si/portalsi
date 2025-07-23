// message_list_page.dart
import 'package:flutter/material.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'chat_room.dart';

class MessageListPage extends StatefulWidget {
  @override
  _MessageListPageState createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> users = [
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
    ChatUser(
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      avatar: "assets/avatar.png",
    ),
  ];

  List<ChatUser> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = users;
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users
          .where(
            (user) =>
                user.name.toLowerCase().contains(query) ||
                user.username.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Pesan',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'rizky',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // User List
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomPage(user: user),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.grey[600]),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user.username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ChatUser {
  final String name;
  final String username;
  final String avatar;

  ChatUser({required this.name, required this.username, required this.avatar});
}
