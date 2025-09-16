// lib/pages/chat_room.dart (SUDAH DIPERBAIKI UNTUK WEB)

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/chat_room_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'package:portal_si/pages/image_preview_screen.dart';

import 'camera_screen.dart';

// --- TAMBAHKAN IMPORT BARU ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

// --- Widget _AssetThumbnail (Tidak ada perubahan) ---
class _AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectionIndex;
  final bool showSelectionOverlay;

  const _AssetThumbnail({
    required this.asset,
    this.isSelected = false,
    this.selectionIndex = 0,
    this.showSelectionOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(color: Colors.grey.shade200);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            if (asset.type == AssetType.video)
              const Positioned(
                bottom: 4,
                right: 4,
                child: Icon(Icons.videocam, color: Colors.white, size: 18),
              ),
            if (isSelected && showSelectionOverlay) ...[
              Container(color: Colors.black.withOpacity(0.6)),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${selectionIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ]
          ],
        );
      },
    );
  }
}

// --- Widget _GalleryPickerSheet (Tidak ada perubahan) ---
class _GalleryPickerSheet extends StatefulWidget {
  const _GalleryPickerSheet();

  @override
  State<_GalleryPickerSheet> createState() => _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends State<_GalleryPickerSheet> {
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (ps.isAuth) {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      if (albums.isNotEmpty) {
        final List<AssetEntity> assets = await albums.first.getAssetListPaged(
          page: 0,
          size: 80,
        );
        if (mounted) {
          setState(() {
            _assets = assets;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedAssets.length,
                itemBuilder: (context, index) {
                  final asset = _selectedAssets[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _AssetThumbnail(asset: asset, showSelectionOverlay: false),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              if (_selectedAssets.isNotEmpty) {
                context.read<ChatRoomController>().sendMediaMessage(_selectedAssets);
                Navigator.pop(context);
              }
            },
            backgroundColor: const Color(0xFF3B82F6),
            child: const Icon(Icons.send),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: const [
                      Text('Recents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: _assets.length,
                    itemBuilder: (context, index) {
                      final asset = _assets[index];
                      final isSelected = _selectedAssets.contains(asset);
                      return GestureDetector(
                        onTap: () => _toggleSelection(asset),
                        child: _AssetThumbnail(
                          asset: asset,
                          isSelected: isSelected,
                          selectionIndex: isSelected ? _selectedAssets.indexOf(asset) : 0,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: _selectedAssets.isNotEmpty
                    ? _buildBottomActionBar()
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- PERUBAHAN UTAMA ADA DI DALAM WIDGET INI ---
class _AttachmentPopupMenu extends StatelessWidget {
  final Offset buttonPosition;
  final Size buttonSize;

  const _AttachmentPopupMenu({
    required this.buttonPosition,
    required this.buttonSize,
  });

  // --- FUNGSI BARU: Untuk memilih dan mengirim gambar di web ---
  Future<void> _pickAndSendImagesForWeb(BuildContext context) async {
    final chatController = context.read<ChatRoomController>();

    // 1. Buka dialog pilih file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true, // Izinkan memilih banyak gambar
    );

    if (result != null && result.files.isNotEmpty) {
      List<AssetEntity> webAssets = [];
      // Tampilkan loading atau status "memproses" jika perlu

      // 2. Loop setiap file yang dipilih dan ubah menjadi AssetEntity
      for (var file in result.files) {
        if (file.bytes != null) {
          try {
            final AssetEntity? asset = await PhotoManager.editor.saveImage(
              file.bytes!,
              filename: file.name,
            );
            if (asset != null) {
              webAssets.add(asset);
            }
          } catch (e) {
            print("Gagal memproses file web: ${file.name}, error: $e");
          }
        }
      }

      // 3. Kirim semua AssetEntity yang berhasil dibuat
      if (webAssets.isNotEmpty) {
        chatController.sendMediaMessage(webAssets);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final popupBottomPosition = screenHeight - buttonPosition.dy;
    final popupRightPosition = screenWidth - (buttonPosition.dx + buttonSize.width);

    return Stack(
      children: [
        Positioned(
          bottom: popupBottomPosition + 8,
          right: popupRightPosition,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupMenuItem(
                    context,
                    icon: Icons.camera_alt_outlined,
                    text: 'Buka Kamera',
                    onTap: () {
                      final navigator = Navigator.of(context);
                      final chatController = context.read<ChatRoomController>();

                      navigator.pop(); // Tutup popup

                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: chatController,
                            child: const CameraScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildPopupMenuItem(
                    context,
                    icon: Icons.image_outlined,
                    text: 'Unggah Gambar',
                    onTap: () {
                      final navigator = Navigator.of(context);
                      final chatController = context.read<ChatRoomController>();

                      navigator.pop(); // Tutup popup

                      // --- LOGIKA KONDISIONAL DI SINI ---
                      if (kIsWeb) {
                        // Jika di web, panggil fungsi baru
                        _pickAndSendImagesForWeb(context);
                      } else {
                        // Jika di mobile, tampilkan galeri lama
                        showModalBottomSheet(
                          context: navigator.context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) {
                            return ChangeNotifierProvider.value(
                              value: chatController,
                              child: const _GalleryPickerSheet(),
                            );
                          },
                        );
                      }
                    },
                  ),
                  _buildPopupMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    text: 'Pilih File',
                    onTap: () {
                      Navigator.pop(context);
                      // Tambahkan logika pilih file dokumen di sini nanti
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenuItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}


// --- Sisa kode dari file chat_room.dart tidak perlu diubah ---
// ...
// (Salin-tempel sisa kode Anda di sini: _BouncyPopupRoute, ChatRoomPage,
// _ChatAppBar, _MessageList, _MessageBubble, dll.)
class _BouncyPopupRoute extends PageRouteBuilder {
  final Offset buttonPosition;
  final Size buttonSize;

  _BouncyPopupRoute({
    required Widget page,
    required this.buttonPosition,
    required this.buttonSize,
  }) : super(
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.15),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final bouncyAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInCubic,
      );

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final buttonCenterX = buttonPosition.dx + (buttonSize.width / 2);
      final buttonCenterY = buttonPosition.dy + (buttonSize.height / 2);

      final alignmentX = (buttonCenterX / screenWidth) * 2 - 1;
      final alignmentY = (buttonCenterY / screenHeight) * 2 - 1;

      final dynamicAlignment = Alignment(alignmentX, alignmentY);

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: ScaleTransition(
          scale: bouncyAnimation,
          alignment: dynamicAlignment,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    },
  );
}

class ChatRoomPage extends StatelessWidget {
  final User user;
  const ChatRoomPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatRoomController(recipient: user),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            image: const DecorationImage(
              image: AssetImage('assets/images/chat_bg.png'),
              fit: BoxFit.cover,
              opacity: 0.05,
            ),
          ),
          child: Column(
            children: [
              _ChatAppBar(user: user),
              Expanded(
                child: Consumer<ChatRoomController>(
                  builder: (context, controller, _) {
                    if (controller.errorMessage != null && !controller.isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (ModalRoute.of(context)?.isCurrent != true) return;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return NetworkErrorDialog(
                              errorMessage: controller.errorMessage!,
                              onRetry: () {
                                Navigator.of(dialogContext).pop();
                                controller.fetchMessages();
                              },
                            );
                          },
                        );
                      });
                      return const _ChatRoomSkeletonLoader();
                    }
                    if (controller.isLoading) {
                      return const _ChatRoomSkeletonLoader();
                    }
                    return _MessageList();
                  },
                ),
              ),
              const _MessageInputBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  const _ChatAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatRoomController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.profilePictureUrl != null &&
                      user.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl!)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.fullName ?? user.username,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        controller.isRecipientOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                            color: controller.isRecipientOnline ? Colors.green.shade600 : Colors.grey.shade600,
                            fontSize: 13
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

class _MessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatRoomController>();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        final bool isMe = message.sender.id == controller.currentUser?.id;

        final bool isGrouped = index < controller.messages.length - 1 &&
            controller.messages[index + 1].sender.id == message.sender.id &&
            message.timestamp
                .difference(controller.messages[index + 1].timestamp)
                .inMinutes <
                2;

        return _MessageBubble(
          message: message,
          isMe: isMe,
          isGrouped: isGrouped,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isGrouped;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGrouped,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? const Color(0xFFFFA726) : Colors.white;
    final timestampColor = isMe ? Colors.white70 : Colors.black54;

    Widget messageContent;

    void _openImagePreview(String path, String tag) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(
            imageUrl: path,
            heroTag: tag,
          ),
        ),
      );
    }

    if (message.type == MessageType.image) {
      // --- PERUBAHAN UTAMA UNTUK MENAMPILKAN GAMBAR ---
      Widget imageWidget;

      if (message.localBytes != null) {
        // 1. Prioritas utama: tampilkan dari bytes untuk preview web
        imageWidget = Image.memory(message.localBytes!, fit: BoxFit.cover);
      } else if (message.localFile != null) {
        // 2. Prioritas kedua: tampilkan dari file untuk preview mobile
        imageWidget = Image.file(message.localFile!, fit: BoxFit.cover);
      } else if (message.mediaUrl != null) {
        // 3. Terakhir: tampilkan dari URL jika sudah ter-upload
        imageWidget = Image.network(
          message.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.grey,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, color: Colors.grey, size: 50);
          },
        );
      } else {
        // Fallback jika tidak ada data gambar sama sekali
        imageWidget = const Icon(Icons.broken_image, color: Colors.grey, size: 50);
      }

      final String? displayImagePath = message.localFile?.path ?? message.mediaUrl;
      final String heroTag = 'image-${message.id}';

      messageContent = GestureDetector(
        onTap: displayImagePath != null ? () => _openImagePreview(displayImagePath, heroTag) : null,
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                imageWidget, // Gunakan widget gambar yang sudah dipilih
                if (message.status == MessageStatus.sending && message.uploadProgress != null)
                  ValueListenableBuilder<double>(
                    valueListenable: message.uploadProgress!,
                    builder: (context, progress, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(color: Colors.black.withOpacity(0.6)),
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GradientCircularProgressIndicator(progress: progress),
                                const SizedBox(height: 8),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                if (message.status == MessageStatus.failed)
                  const Icon(Icons.error, color: Colors.red, size: 40),
              ],
            ),
          ),
        ),
      );
    } else {
      messageContent = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message.text ?? "",
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.Hm().format(message.timestamp),
                  style: TextStyle(color: timestampColor, fontSize: 12),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 16,
                    color: message.status == MessageStatus.read
                        ? Colors.lightBlue.shade100
                        : timestampColor,
                  ),
                ]
              ],
            ),
          )
        ],
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: EdgeInsets.only(
          top: isGrouped ? 2.0 : 10.0,
          bottom: 2.0,
        ),
        decoration: BoxDecoration(
          color: (message.type == MessageType.text || message.text != null) ? color : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe || isGrouped ? const Radius.circular(20) : const Radius.circular(5),
            bottomRight: !isMe || isGrouped ? const Radius.circular(20) : const Radius.circular(5),
          ),
          boxShadow: (message.type == MessageType.text || message.text != null) ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        padding: (message.type == MessageType.text || message.text != null)
            ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0)
            : const EdgeInsets.all(4.0),
        child: messageContent,
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time_rounded;
      case MessageStatus.sent:
        return Icons.done_rounded;
      case MessageStatus.read:
        return Icons.done_all_rounded;
      case MessageStatus.failed:
        return Icons.error_outline_rounded;
      default:
        return Icons.done_rounded;
    }
  }
}

class _GradientCircularProgressIndicator extends StatelessWidget {
  final double progress;
  const _GradientCircularProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * 3.14,
          stops: [0.0, 1.0],
          colors: [Colors.orange, Colors.deepOrange],
        ).createShader(rect);
      },
      child: CircularProgressIndicator(
        value: progress,
        valueColor: const AlwaysStoppedAnimation(Colors.white),
        strokeWidth: 4,
        backgroundColor: Colors.white.withOpacity(0.3),
      ),
    );
  }
}

class _MessageInputBar extends StatefulWidget {
  const _MessageInputBar();

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _attachIconKey = GlobalKey();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.read<ChatRoomController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Ketik pesan...',
              ),
              maxLines: 5,
              minLines: 1,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          if (!kIsWeb)
            IconButton(
              key: _attachIconKey,
              icon: const Icon(Icons.attach_file_rounded, color: Colors.black54),
              onPressed: () {
                final RenderBox renderBox =
                _attachIconKey.currentContext!.findRenderObject() as RenderBox;
                final size = renderBox.size;
                final position = renderBox.localToGlobal(Offset.zero);

                final chatController = context.read<ChatRoomController>();

                Navigator.of(context).push(
                  _BouncyPopupRoute(
                    buttonPosition: position,
                    buttonSize: size,
                    page: ChangeNotifierProvider.value(
                      value: chatController,
                      child: _AttachmentPopupMenu(
                        buttonPosition: position,
                        buttonSize: size,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_textController.text.trim().isNotEmpty)
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFFA726),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_textController.text
                      .trim()
                      .isNotEmpty) {
                    chatController.sendMessage(_textController.text);
                    _textController.clear();
                    setState(() {});
                  }
                },
              ),
            ),

        ],
      ),
    );
  }
}

class _ChatRoomSkeletonLoader extends StatelessWidget {
  const _ChatRoomSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
        itemBuilder: (context, index) {
          final randomWidth = 100.0 + Random().nextDouble() * 150.0;
          final isMe = index.isEven;

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              height: 40.0,
              width: randomWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NetworkErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const NetworkErrorDialog({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '😩',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Jaringan Anda Bermasalah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                color: Color(0xFF4D0015),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Terdapat masalah pada jaringan Anda. Klik tombol muat ulang dibawah ini atau coba untuk mulai ulang aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Muat Ulang',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Laporkan ke Admin: $errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8.0),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14.0, color: Colors.black87),
                children: [
                  TextSpan(text: 'Bentuk partisipasi Anda adalah '),
                  TextSpan(
                    text: 'sangat bermanfaat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' bagi kami.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}