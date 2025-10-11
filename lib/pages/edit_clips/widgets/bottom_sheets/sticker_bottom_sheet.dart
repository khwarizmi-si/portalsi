import 'package:flutter/material.dart';
import '../../../../models/text_overlay_model.dart';

class StickerBottomSheet extends StatelessWidget {
  final ValueChanged<TextOverlay> onTextStickerSelected;
  final VoidCallback onGenerateCaptions;
  final VoidCallback onLocationTap;
  final VoidCallback onGifTap;
  final VoidCallback onPhotoTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onCutoutTap;

  const StickerBottomSheet({
    super.key,
    required this.onTextStickerSelected,
    required this.onGenerateCaptions,
    required this.onLocationTap,
    required this.onGifTap,
    required this.onPhotoTap,
    required this.onAvatarTap,
    required this.onCutoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onCutoutTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cut_outlined, color: Colors.white, size: 28),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Create with Cutouts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text(
                                  'Turn photos into stickers to use in reels and stories.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStickerOptionChip(
                        label: 'LOCATION',
                        icon: Icons.location_on,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        onTap: onLocationTap,
                      ),
                      _buildStickerOptionChip(
                        label: 'CAPTIONS',
                        icon: Icons.closed_caption,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        onTap: onGenerateCaptions,
                      ),
                      _buildStickerOptionChip(
                        label: 'QUIZ',
                        icon: Icons.check_circle,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        onTap: () => onTextStickerSelected(TextOverlay(text: 'Quiz: What is the answer?', backgroundStyle: TextBackgroundStyle.solid, color: Colors.deepPurple, position: const Offset(50, 150))),
                      ),
                      _buildStickerOptionChip(
                        label: '❤️',
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.red,
                        isEmoji: true,
                        onTap: () => onTextStickerSelected(TextOverlay(text: '❤️', backgroundStyle: TextBackgroundStyle.none, scale: 3.0, position: const Offset(150, 200))),
                      ),
                      _buildStickerOptionChip(
                        label: 'GIF',
                        icon: Icons.gif_box_outlined,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        onTap: onGifTap,
                      ),
                      _buildStickerOptionChip(
                        label: 'PHOTO',
                        icon: Icons.photo,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        onTap: onPhotoTap,
                      ),
                      _buildStickerOptionChip(
                        label: 'AVATAR',
                        icon: Icons.person_outline,
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        onTap: onAvatarTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPlaceholderSticker(
                        Text(timeString, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        onTap: () => onTextStickerSelected(TextOverlay(text: timeString, backgroundStyle: TextBackgroundStyle.semiTransparent, position: const Offset(100, 100))),
                      ),
                      _buildPlaceholderSticker(
                        const Icon(Icons.favorite, color: Colors.white, size: 40),
                        color: Colors.red,
                        onTap: () => onTextStickerSelected(TextOverlay(text: '😍', backgroundStyle: TextBackgroundStyle.none, scale: 3.0, position: const Offset(130, 220))),
                      ),
                      _buildPlaceholderSticker(
                        const Text("TUESDAY", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                        onTap: () => onTextStickerSelected(TextOverlay(text: 'TUESDAY', backgroundStyle: TextBackgroundStyle.none, color: Colors.amber, scale: 2.0, position: const Offset(110, 180))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildStickerOptionChip({
    required String label,
    IconData? icon,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isEmoji = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: isEmoji ? 4 : 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: foregroundColor, size: 18),
            if (icon != null && !isEmoji) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: isEmoji ? 24 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderSticker(Widget child, {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color ?? Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: child),
      ),
    );
  }
}