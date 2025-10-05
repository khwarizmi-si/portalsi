// lib/widgets/custom_emoji_picker.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/emoji_model.dart';

class CustomEmojiPicker extends StatefulWidget {
  const CustomEmojiPicker({super.key});

  @override
  State<CustomEmojiPicker> createState() => _CustomEmojiPickerState();
}

class _CustomEmojiPickerState extends State<CustomEmojiPicker> with SingleTickerProviderStateMixin {
  List<Emoji> _allEmojis = [];
  final List<List<Emoji>> _categorizedEmojis = List.generate(10, (_) => []);
  bool _isLoading = true;
  late TabController _tabController;

  // Nama kategori sesuai urutan 'group' di file JSON
  final List<String> _categoryNames = [
    "Smileys & Emotion",
    "People & Body",
    "Animals & Nature",
    "Food & Drink",
    "Travel & Places",
    "Activities",
    "Objects",
    "Symbols",
    "Flags",
  ];

  // Icon untuk setiap kategori
  final List<IconData> _categoryIcons = [
    Icons.sentiment_satisfied,
    Icons.person,
    Icons.pets,
    Icons.fastfood,
    Icons.location_city,
    Icons.sports_soccer,
    Icons.lightbulb,
    Icons.emoji_symbols,
    Icons.flag,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryNames.length, vsync: this);
    _loadEmojis();
  }

  Future<void> _loadEmojis() async {
    try {
      final String response = await rootBundle.loadString('assets/emojis.json');
      final List<dynamic> data = await json.decode(response);
      _allEmojis = data.map((e) => Emoji.fromJson(e)).toList();

      // Kelompokkan emoji berdasarkan grupnya
      for (var emoji in _allEmojis) {
        if (emoji.group >= 0 && emoji.group < _categorizedEmojis.length) {
          _categorizedEmojis[emoji.group].add(emoji);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading emojis: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: List.generate(_categoryNames.length, (index) {
              return Tab(icon: Icon(_categoryIcons[index]));
            }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_categoryNames.length, (index) {
                final emojis = _categorizedEmojis[index];
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        // Kembalikan emoji yang dipilih saat di-tap
                        Navigator.pop(context, emojis[i].emoji);
                      },
                      child: Center(
                        child: Text(
                          emojis[i].emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}