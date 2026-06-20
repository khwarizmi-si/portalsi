// lib/pages/chat_info_page.dart
//
// Instagram-style chat info: recipient header + "view profile" shortcut and
// the media/links shared in this conversation, grouped into tabs.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'other_profile_page.dart';

class ChatInfoPage extends StatelessWidget {
  final User user;
  final List<ChatMessage> messages;

  const ChatInfoPage({super.key, required this.user, required this.messages});

  static final _linkRegex = RegExp(r'https?:\/\/[^\s]+');

  @override
  Widget build(BuildContext context) {
    final media = messages
        .where((m) => (m.mediaUrl ?? '').isNotEmpty)
        .toList();
    final links = <String>[];
    for (final m in messages) {
      for (final match in _linkRegex.allMatches(m.text ?? '')) {
        links.add(match.group(0)!);
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: const Text('Info'),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey[200],
              backgroundImage: (user.profilePictureUrl ?? '').isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: (user.profilePictureUrl ?? '').isEmpty
                  ? Text(
                      (user.username.isNotEmpty ? user.username[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(user.fullName ?? user.username,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('@${user.username}',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OtherProfilePage(username: user.username),
                ),
              ),
              icon: const Icon(Icons.person_outline),
              label: const Text('Lihat Profil'),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: Colors.black,
              tabs: [Tab(text: 'Media'), Tab(text: 'Tautan')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _mediaGrid(media),
                  _linkList(links),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaGrid(List<ChatMessage> media) {
    if (media.isEmpty) {
      return const Center(
          child: Text('Belum ada media', style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (_, i) => CachedNetworkImage(
        imageUrl: media[i].mediaUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
      ),
    );
  }

  Widget _linkList(List<String> links) {
    if (links.isEmpty) {
      return const Center(
          child: Text('Belum ada tautan', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      itemCount: links.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.link),
        title: Text(links[i], maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          final uri = Uri.tryParse(links[i]);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}
