// lib/pages/edit_clips/widgets/toolbars/edit_clips_toolbar.dart

import 'package:flutter/material.dart';

class EditClipsToolbar extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTextTap;
  final VoidCallback onEmojiTap;
  final VoidCallback onStickerTap;
  final VoidCallback onEffectsTap;
  final VoidCallback onNextTap;

  const EditClipsToolbar({
    super.key,
    required this.isProcessing,
    required this.onTextTap,
    required this.onEmojiTap,
    required this.onStickerTap,
    required this.onEffectsTap,
    required this.onNextTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Edit video', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : onNextTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05), // Spasi dinamis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(Icons.text_fields_sharp, onTextTap),
                _buildToolbarButton(Icons.sentiment_satisfied_alt_outlined, onEmojiTap),
                _buildToolbarButton(Icons.auto_awesome_outlined, onEffectsTap),
                _buildToolbarButton(Icons.sticky_note_2_outlined, onStickerTap),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 28),
      onPressed: onPressed,
    );
  }
}