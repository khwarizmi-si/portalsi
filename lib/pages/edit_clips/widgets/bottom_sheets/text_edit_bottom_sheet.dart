// lib/pages/edit_clips/widgets/bottom_sheets/text_edit_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../../models/text_overlay_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Tambahkan paket ini

// Pastikan Anda sudah menambahkan flutter_colorpicker di pubspec.yaml
// dependencies:
//   flutter_colorpicker: ^1.0.0

class TextEditBottomSheet extends StatefulWidget {
  final TextOverlay textOverlay;
  final ValueChanged<TextOverlay> onOverlayChanged;
  final VoidCallback onDelete;

  const TextEditBottomSheet({
    super.key,
    required this.textOverlay,
    required this.onOverlayChanged,
    required this.onDelete,
  });

  @override
  State<TextEditBottomSheet> createState() => _TextEditBottomSheetState();
}

class _TextEditBottomSheetState extends State<TextEditBottomSheet> {
  late TextOverlay _currentOverlay;

  // Daftar contoh font. Anda bisa menambahkan lebih banyak.
  static const List<String> _fontFamilies = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Oswald',
    'Pacifico', // Font gaya tulisan tangan
    'Press Start 2P', // Font retro pixel
  ];

  @override
  void initState() {
    super.initState();
    _currentOverlay = widget.textOverlay.copyWith(); // Buat salinan untuk diedit
  }

  void _updateOverlay() {
    widget.onOverlayChanged(_currentOverlay);
  }

  void _changeTextColor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Text('Pilih Warna Teks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: BlockPicker(
                pickerColor: _currentOverlay.color,
                onColorChanged: (color) {
                  setState(() {
                    _currentOverlay.color = color;
                    _updateOverlay();
                  });
                },
                availableColors: const [
                  Colors.white, Colors.black, Colors.red, Colors.pink,
                  Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue,
                  Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
                  Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber,
                  Colors.orange, Colors.deepOrange, Colors.brown, Colors.grey,
                  Colors.blueGrey
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opsi Font Family
            _buildEditOption(
              label: 'Font',
              icon: Icons.font_download_outlined,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => _buildFontPickerSheet(),
                  backgroundColor: Colors.transparent,
                );
              },
              trailingWidget: Text(
                _currentOverlay.fontFamily,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _currentOverlay.fontFamily,
                  fontSize: 14,
                ),
              ),
            ),

            // Opsi Ketebalan Font
            _buildEditOption(
              label: 'Ketebalan',
              icon: _currentOverlay.fontWeight == FontWeight.bold
                  ? Icons.format_bold
                  : Icons.format_align_center, // Icon default jika tidak bold
              onTap: () {
                setState(() {
                  _currentOverlay.fontWeight = _currentOverlay.fontWeight == FontWeight.bold
                      ? FontWeight.normal
                      : FontWeight.bold;
                  _updateOverlay();
                });
              },
            ),

            // Opsi Warna Font
            _buildEditOption(
              label: 'Warna',
              icon: Icons.color_lens_outlined,
              onTap: () => _changeTextColor(context),
              trailingWidget: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentOverlay.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
              ),
            ),

            // Opsi Gaya Latar Belakang
            _buildEditOption(
              label: 'Latar Belakang',
              icon: Icons.square_foot,
              onTap: () {
                setState(() {
                  final nextStyle = TextBackgroundStyle.values[
                  (_currentOverlay.backgroundStyle.index + 1) %
                      TextBackgroundStyle.values.length];
                  _currentOverlay.backgroundStyle = nextStyle;
                  _updateOverlay();
                });
              },
              trailingWidget: Text(
                _currentOverlay.backgroundStyle.name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),

            // Opsi Perataan Teks
            _buildEditOption(
              label: 'Perataan',
              icon: _currentOverlay.textAlign == TextAlign.left ? Icons.format_align_left :
              _currentOverlay.textAlign == TextAlign.center ? Icons.format_align_center :
              Icons.format_align_right,
              onTap: () {
                setState(() {
                  final nextAlign = TextAlign.values[
                  (_currentOverlay.textAlign.index + 1) %
                      TextAlign.values.length];
                  _currentOverlay.textAlign = nextAlign;
                  _updateOverlay();
                });
              },
            ),

            // Opsi Hapus
            _buildEditOption(
              label: 'Hapus',
              icon: Icons.delete_outline,
              onTap: () {
                Navigator.of(context).pop(); // Tutup sheet
                widget.onDelete(); // Panggil callback delete
              },
              iconColor: Colors.red,
              labelColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailingWidget,
    Color iconColor = Colors.white,
    Color labelColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 16),
              ),
            ),
            if (trailingWidget != null) trailingWidget,
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFontPickerSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Text('Pilih Font', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _fontFamilies.length,
              itemBuilder: (context, index) {
                final fontFamily = _fontFamilies[index];
                return ListTile(
                  title: Text(
                    fontFamily,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontFamily,
                      fontSize: 18,
                      fontWeight: _currentOverlay.fontFamily == fontFamily
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _currentOverlay.fontFamily == fontFamily
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _currentOverlay.fontFamily = fontFamily;
                      _updateOverlay();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}