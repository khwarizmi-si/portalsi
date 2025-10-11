// lib/pages/edit_clips/widgets/bottom_sheets/effects_bottom_sheet.dart

import 'package:flutter/material.dart';

class EffectsBottomSheet extends StatelessWidget {
  final String selectedEffectName;
  final ValueChanged<String> onEffectSelected;

  const EffectsBottomSheet({
    super.key,
    required this.selectedEffectName,
    required this.onEffectSelected,
  });

  static const List<Map<String, dynamic>> _effects = [
    {'name': 'No effect', 'icon': Icons.block},
    {'name': 'Grayscale', 'icon': Icons.filter_b_and_w},
    {'name': 'Sepia', 'icon': Icons.colorize},
    {'name': 'Vivid', 'icon': Icons.tonality},
    {'name': 'Bubble Captions', 'icon': Icons.chat_bubble_outline},
    {'name': 'Soft Nature', 'icon': Icons.eco_outlined},
    {'name': 'Teal & tangerine', 'icon': Icons.palette_outlined},
    {'name': 'HDR', 'icon': Icons.hdr_on_outlined},
    {'name': 'Indie Trip', 'icon': Icons.movie_filter_outlined},
    {'name': '8K Quality', 'icon': Icons.high_quality_outlined},
    {'name': 'Old Video', 'icon': Icons.filter_vintage_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Efek Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
                ),
                itemCount: _effects.length,
                itemBuilder: (context, index) {
                  final effect = _effects[index];
                  final bool isSelected = selectedEffectName == effect['name'];
                  return GestureDetector(
                    onTap: () => onEffectSelected(effect['name']),
                    child: _buildEffectItem(effect['name'], effect['icon'], isSelected),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEffectItem(String name, IconData icon, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
            color: Colors.grey.shade800,
          ),
          child: ClipOval(
            child: Center(
              child: Icon(icon, color: Colors.white, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}