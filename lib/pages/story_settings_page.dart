// lib/pages/story_settings_page.dart

import 'package:flutter/material.dart';

class StorySettingsPage extends StatefulWidget {
  const StorySettingsPage({Key? key}) : super(key: key);

  @override
  _StorySettingsPageState createState() => _StorySettingsPageState();
}

class _StorySettingsPageState extends State<StorySettingsPage> {
  // State untuk setiap pengaturan
  int _replyingOption = 1; // 1: Everyone, 2: People you follow, 3: Off
  bool _allowComments = true;
  bool _saveToGallery = false;
  bool _saveToArchive = true;
  bool _allowSharingToStory = true;
  bool _allowSharingToMessages = true;
  bool _shareToFacebook = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cerita',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Simpan pengaturan
              print('Pengaturan Story disimpan!');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Simpan',
              style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildSectionHeader('Pelihat'),
          _buildNavigationTile(
            title: 'Sembunyikan cerita anda dari',
            subtitle: '0 orang',
            onTap: () {},
          ),
          _buildNavigationTile(
            title: 'Teman dekat',
            subtitle: '0 orang',
            onTap: () {},
          ),
          const Divider(color: Colors.white24, height: 32),

          _buildSectionHeader('Membalas'),
          const Text('Izinkan pesan di balas', style: TextStyle(color: Colors.white, fontSize: 16)),
          const Text('Pilih siapa saja yang bisa membalas ke cerita anda.', style: TextStyle(color: Colors.grey)),
          _buildRadioTile<int>('Semuanya', 1, _replyingOption, (val) => setState(() => _replyingOption = val!)),
          _buildRadioTile<int>('Orang yang saya ikuti', 2, _replyingOption, (val) => setState(() => _replyingOption = val!)),
          _buildRadioTile<int>('Tidak satupun', 3, _replyingOption, (val) => setState(() => _replyingOption = val!)),
          const Divider(color: Colors.white24, height: 32),

          _buildSectionHeader('Commenting'),
          _buildSwitchTile(
            title: 'Allow comments',
            subtitle: 'Choose who can leave comments on your story.',
            value: _allowComments,
            onChanged: (val) => setState(() => _allowComments = val),
          ),
          const Divider(color: Colors.white24, height: 32),

          _buildSwitchTile(
            title: 'Save story to Gallery',
            subtitle: 'Automatically save your story to your phone\'s gallery.',
            value: _saveToGallery,
            onChanged: (val) => setState(() => _saveToGallery = val),
          ),
          _buildSwitchTile(
            title: 'Save story to archive',
            subtitle: 'Automatically save your story to your archive so you don\'t have to save it to your phone. Only you can see your archive.',
            value: _saveToArchive,
            onChanged: (val) => setState(() => _saveToArchive = val),
          ),
          const Divider(color: Colors.white24, height: 32),

          _buildSectionHeader('Sharing'),
          _buildSwitchTile(
            title: 'Allow sharing to story',
            subtitle: 'Other people can add your feed posts and IGTV videos to their stories. Your username will always show up with your post.',
            value: _allowSharingToStory,
            onChanged: (val) => setState(() => _allowSharingToStory = val),
          ),
          _buildSwitchTile(
            title: 'Allow sharing to messages',
            subtitle: 'Let others share photos and videos from your story in a message.',
            value: _allowSharingToMessages,
            onChanged: (val) => setState(() => _allowSharingToMessages = val),
          ),
          _buildSwitchTile(
            title: 'Share your story to Facebook',
            subtitle: 'Automatically share your Instagram story as your Facebook story.',
            value: _shareToFacebook,
            onChanged: (val) => setState(() => _shareToFacebook = val),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat judul bagian
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper untuk membuat baris yang bisa dinavigasi
  Widget _buildNavigationTile({required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // Helper untuk membuat radio button
  Widget _buildRadioTile<T>(String title, T value, T groupValue, ValueChanged<T?> onChanged) {
    return RadioListTile<T>(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }

  // Helper untuk membuat switch
  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
      inactiveTrackColor: Colors.grey[800],
    );
  }
}