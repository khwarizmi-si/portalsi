// lib/pages/chat_room.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../components/verified_badge.dart'; // <-- 1. IMPORT VERIFIED BADGE
import '../controllers/chat_room_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'package:portal_si/pages/image_preview_screen.dart';

import '../widgets/permission_dialog.dart';
import 'camera_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

import 'full_screen_image_viewer.dart';

// --- Widget _AssetThumbnail ---
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

// --- Widget _GalleryPickerSheet ---
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
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

class _AttachmentPopupMenu extends StatelessWidget {
  final Offset buttonPosition;
  final Size buttonSize;

  const _AttachmentPopupMenu({
    required this.buttonPosition,
    required this.buttonSize,
  });

  Future<void> _pickAndSendImagesForWeb(BuildContext context) async {
    final chatController = context.read<ChatRoomController>();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<AssetEntity> webAssets = [];
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

                      navigator.pop();

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

                      navigator.pop();

                      if (kIsWeb) {
                        _pickAndSendImagesForWeb(context);
                      } else {
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

class ChatRoomPage extends StatefulWidget {
  final User user;
  const ChatRoomPage({super.key, required this.user});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late final ChatRoomController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatRoomController(recipient: widget.user);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestNotificationPermission();
    });
  }

  Future<void> _checkAndRequestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isDenied && mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => NotificationPermissionDialog(
          onLater: () => Navigator.of(context).pop(),
          onAllow: () async {
            Navigator.of(context).pop();
            await Permission.notification.request();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatController,
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
              _ChatAppBar(user: widget.user),
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
                      // -- 👇 MODIFIKASI DIMULAI DI SINI 👇 --
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName ?? user.username,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6,),
                          if (user.isVerified)
                            const VerifiedBadge(size: 17),
                        ],
                      ),
                      // -- 👆 MODIFIKASI SELESAI DI SINI 👆 --
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
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.black.withOpacity(0.7)),
                  onSelected: (String value) {
                    if (value == 'reload') {
                      Provider.of<ChatRoomController>(context, listen: false)
                          .reloadConversation();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'reload',
                      child: Text('Muat ulang percakapan'),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: controller.messages.length + 1,
      itemBuilder: (context, index) {

        if (index == controller.messages.length) {
          return const SizedBox(height: 20);
        }

        final message = controller.messages[index];
        final bool isMe = message.sender.id == controller.currentUser?.id;

        final bool showSenderName = !isMe &&
            (index == controller.messages.length - 1 ||
                index == 0 ||
                (index > 0 && controller.messages[index - 1].sender.id != message.sender.id));

        return _MessageBubble(
          message: message,
          isMe: isMe,
          showSenderName: showSenderName,
          sender: message.sender,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSenderName;
  final User? sender;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
    this.sender,
  });

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return const Text("📹 Video (belum didukung)");
      case MessageType.file:
        return const Text("📎 File (belum didukung)");
      case MessageType.text:
      default:
        return Text(message.text ?? '',
            style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.3));
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    ImageProvider imageProvider;

    if (message.localBytes != null) {
      imageProvider = MemoryImage(message.localBytes!);
    } else if (message.localFile != null) {
      imageProvider = FileImage(message.localFile!);
    } else if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
      imageProvider = NetworkImage(message.mediaUrl!);
    } else {
      return const Icon(Icons.broken_image, color: Colors.grey, size: 50);
    }

    final String heroTag = message.id.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withOpacity(0.7),
            pageBuilder: (BuildContext context, _, __) {
              return FullScreenImageViewer(
                imageProvider: imageProvider,
                heroTag: heroTag,
              );
            },
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            child: Image(
              image: imageProvider,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error_outline, color: Colors.red, size: 40);
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    if (messageDay.isAtSameMomentAs(today)) {
      return DateFormat.Hm().format(localDateTime);
    } else if (messageDay.isAtSameMomentAs(yesterday)) {
      return 'Kemarin, ${DateFormat.Hm().format(localDateTime)}';
    } else if (now.difference(messageDay).inDays < 7) {
      return DateFormat('EEEE, Hm').format(localDateTime);
    } else {
      return DateFormat('d MMMM yyyy, Hm').format(localDateTime);
    }
  }

  static Color getSenderColor(String senderId) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];
    return colors[senderId.hashCode % colors.length];
  }

  Color _getSenderColor(String senderId) {
    return getSenderColor(senderId);
  }

  @override
  Widget build(BuildContext context) {
    final messageSender = sender ?? message.sender;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 2, bottom: 2, left: isMe ? 64 : 16, right: isMe ? 16 : 64),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isMe && sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: sender!.profilePictureUrl != null
                          ? NetworkImage(sender!.profilePictureUrl!)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sender!.fullName ?? sender!.username,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(message.sender.id.toString()),
                      ),
                    ),
                    if (messageSender.isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.verified, size: 14, color: Colors.blue.shade500),
                      ),
                  ],
                ),
              ),

            Container(
              padding: message.type == MessageType.text
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF8D42) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  if (message.type == MessageType.text)
                    const SizedBox(height: 4),

                  Padding(
                    padding: message.type == MessageType.text
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(top: 4.0, right: 4.0),
                    child: Text(_formatTime(message.timestamp),
                        style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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