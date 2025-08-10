// lib/widgets/collage_layout_view.dart

import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CollageLayoutView extends StatelessWidget {
  final List<AssetEntity> assets;

  const CollageLayoutView({Key? key, required this.assets}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const gap = Padding(padding: EdgeInsets.all(1.5)); // Jarak antar gambar

    if (assets.isEmpty) {
      // Tampilan fallback jika tidak ada aset
      return const Center(child: Icon(Icons.photo_library_outlined, color: Colors.white60, size: 48));
    }

    // Layout untuk 2 gambar
    if (assets.length == 2) {
      return Row(children: [
        Expanded(child: AssetEntityImage(assets[0], fit: BoxFit.cover, height: double.infinity)),
        gap,
        Expanded(child: AssetEntityImage(assets[1], fit: BoxFit.cover, height: double.infinity)),
      ]);
    }

    // Layout untuk 3 gambar
    if (assets.length == 3) {
      return Column(children: [
        Expanded(flex: 2, child: AssetEntityImage(assets[0], fit: BoxFit.cover, width: double.infinity)),
        gap,
        Expanded(flex: 1, child: Row(children: [
          Expanded(child: AssetEntityImage(assets[1], fit: BoxFit.cover, height: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[2], fit: BoxFit.cover, height: double.infinity)),
        ])),
      ]);
    }

    // Layout untuk 4 gambar (2x2 Grid)
    if (assets.length == 4) {
      return Column(children: [
        Expanded(child: Row(children: [
          Expanded(child: AssetEntityImage(assets[0], fit: BoxFit.cover, height: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[1], fit: BoxFit.cover, height: double.infinity)),
        ])),
        gap,
        Expanded(child: Row(children: [
          Expanded(child: AssetEntityImage(assets[2], fit: BoxFit.cover, height: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[3], fit: BoxFit.cover, height: double.infinity)),
        ])),
      ]);
    }

    // Layout untuk 5 gambar
    if (assets.length == 5) {
      return Row(children: [
        Expanded(flex: 2, child: Column(children: [
          Expanded(child: AssetEntityImage(assets[0], fit: BoxFit.cover, width: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[1], fit: BoxFit.cover, width: double.infinity)),
        ])),
        gap,
        Expanded(flex: 3, child: Column(children: [
          Expanded(child: AssetEntityImage(assets[2], fit: BoxFit.cover, width: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[3], fit: BoxFit.cover, width: double.infinity)),
          gap,
          Expanded(child: AssetEntityImage(assets[4], fit: BoxFit.cover, width: double.infinity)),
        ])),
      ]);
    }

    // Layout default untuk 1 atau 6+ gambar
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: assets.length == 1 ? 1 : 2, // 1 kolom jika hanya 1 gambar, else 2
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return AssetEntityImage(assets[index], isOriginal: false, fit: BoxFit.cover);
      },
    );
  }
}