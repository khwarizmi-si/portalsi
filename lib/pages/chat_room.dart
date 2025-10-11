// lib/pages/chat_room.dart (FINAL DENGAN PERBAIKAN BUG)

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:portal_si/pages/story_view_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:collection/collection.dart';

import '../components/verified_badge.dart';
import '../controllers/chat_room_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'package:portal_si/pages/image_preview_screen.dart';

import '../services/story_service.dart';
import '../widgets/permission_dialog.dart';
import 'camera_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

import 'full_screen_image_viewer.dart';

// ===== PALET WARNA =====
const Color kLightSurfaceColor = Colors.white;
const Color kSentBubbleColor = Color(0xFFFF9A47);
const Color kReceivedBubbleColor = Color(0xFFE9E9EB);
const Color kTextColor = Colors.black87;
const Color kSentTextColor = Colors.white;
const Color kSubtleTextColor = Colors.black54;
// ===============================================

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
                    color: kSentBubbleColor,
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
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.grey.shade200))
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
            backgroundColor: kSentBubbleColor,
            child: const Icon(Icons.send, color: kSentTextColor,),
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
        return Container(
          decoration: const BoxDecoration(
              color: kLightSurfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        const Text('Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextColor)),
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
          ),
        );
      },
    );
  }
}

// === ANIMASI ROUTE BARU ===
class _FadeSlideUpRoute extends PageRouteBuilder {
  final Widget page;
  final Offset buttonPosition;
  final Size buttonSize;

  _FadeSlideUpRoute({
    required this.page,
    required this.buttonPosition,
    required this.buttonSize,
  }) : super(
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.15),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuint);

      final screenHeight = MediaQuery.of(context).size.height;
      final popupBottomPosition = screenHeight - buttonPosition.dy;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // --- PERBAIKAN POSISI ADA DI SINI ---
          Positioned(
            // Atur jarak dari bawah layar agar tepat di atas tombol
            bottom: popupBottomPosition + 8,

            // Atur jarak dari kiri layar sesuai posisi tombol
            left: buttonPosition.dx,

            child: FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

// === WIDGET POPUP MENU YANG DIPERBARUI ===
class _AttachmentPopupMenu extends StatelessWidget {
  const _AttachmentPopupMenu({super.key});

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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: kLightSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPopupMenuItem(
              context,
              icon: Icons.camera_alt_rounded,
              text: 'Kamera',
              iconBackgroundColor: Colors.pink,
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
              icon: Icons.image_rounded,
              text: 'Galeri',
              iconBackgroundColor: Colors.purple,
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
                    backgroundColor: Colors.transparent,
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
              icon: Icons.insert_drive_file_rounded,
              text: 'Dokumen',
              iconBackgroundColor: Colors.orange,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenuItem(BuildContext context,
      {required IconData icon,
        required String text,
        required VoidCallback onTap,
        required Color iconBackgroundColor}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(color: kTextColor, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final User user;
  final String? initialReplyText;
  final int? initialStoryId;
  final String? initialStoryMediaUrl;

  const ChatRoomPage({
    super.key,
    required this.user,
    this.initialReplyText,
    this.initialStoryId,
    this.initialStoryMediaUrl,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late final ChatRoomController _chatController;
  final ScrollController _scrollController = ScrollController();
  bool _showJumpToBottom = false;

  @override
  void initState() {
    super.initState();
    _chatController = ChatRoomController(recipient: widget.user);
    _scrollController.addListener(_scrollListener);
    _initializeAndSendInitialMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // --- 👇 TAMBAHKAN LOGIKA UNTUK MENGIRIM PESAN AWAL 👇 ---
      // Cek apakah ada "paket data" balasan cerita yang dibawa
      if (widget.initialReplyText != null && widget.initialStoryId != null) {
        // Jika ada, panggil controller untuk mengirimnya
        _chatController.sendStoryResponseMessage(
          widget.initialReplyText!,
          widget.initialStoryId!,
          widget.initialStoryMediaUrl,
        );
      }
      // --- 👆 BATAS PENAMBAHAN 👆 ---

      if (!kIsWeb) {
        _checkAndRequestNotificationPermission();
      }
    });

  }

  void _scrollListener() {
    if (_scrollController.offset > 300) {
      if (!_showJumpToBottom) {
        setState(() => _showJumpToBottom = true);
      }
    } else {
      if (_showJumpToBottom) {
        setState(() => _showJumpToBottom = false);
      }
    }
  }

  void _jumpToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _openStoryFromChat(ChatMessage message) async {
    if (message.recipient.id == null || message.storyId == null) return;

    // TIDAK PERLU LAGI MENGAMBIL DATA DI SINI.
    // Cukup navigasi langsung.

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewPage(
          initialUserId: message.recipient.id!, // KIRIM USER ID PENERIMA
          initialStoryId: message.storyId, // KIRIM STORY ID AWAL
          heroTag: 'story_from_chat_${message.storyId}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndSendInitialMessage() async {
    // 1. TUNGGU sampai semua proses inisialisasi di controller selesai
    await _chatController.initialize();

    // 2. SETELAH SELESAI, baru kita kirim pesan awal jika ada
    if (widget.initialReplyText != null && widget.initialStoryId != null && mounted) {
      _chatController.sendStoryResponseMessage(
        widget.initialReplyText!,
        widget.initialStoryId!,
        widget.initialStoryMediaUrl,
      );
    }

    // Pindahkan pengecekan izin notifikasi ke sini
    if (!kIsWeb && mounted) {
      _checkAndRequestNotificationPermission();
    }
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFEDB3),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ChangeNotifierProvider.value(
        value: _chatController,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFEDB3),
          appBar: null,
          body: Column(
            children: [
              _ChatAppBar(user: widget.user),
              // Consumer<ChatRoomController>(
              //   builder: (context, controller, _) {
              //     if (controller.debugStatus == null) {
              //       return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika null
              //     }
              //     return Container(
              //       width: double.infinity,
              //       color: Colors.yellow.shade200,
              //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //       child: Text(
              //         controller.debugStatus!,
              //         textAlign: TextAlign.center,
              //         style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              //       ),
              //     );
              //   },
              // ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: Container(
                    color: kLightSurfaceColor,
                    child: Stack(
                      children: [
                        Consumer<ChatRoomController>(
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
                                        // PERBAIKAN: Pemanggilan loadMessages
                                        controller.fetchMessages();
                                      },
                                    );
                                  },
                                );
                              });
                              return const _ChatRoomSkeletonLoader();
                            }
                            if (controller.isLoading && controller.messages.isEmpty) {
                              return const _ChatRoomSkeletonLoader();
                            }
                            return _MessageList(scrollController: _scrollController, currentUser: controller.currentUser);
                          },
                        ),
                        if (_showJumpToBottom)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              onPressed: _jumpToBottom,
                              backgroundColor: kLightSurfaceColor,
                              elevation: 3,
                              child: const Icon(Icons.arrow_downward, color: kTextColor, size: 20,),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // PERBAIKAN: Hapus const
              const _MessageInputBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final User user;
  const _ChatAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFFFFEDB3),
        // border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: kTextColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage:
              user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.fullName ?? user.username,
                      style: const TextStyle(
                          color: kTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(size: 17),
                  ]
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call_outlined, color: kSubtleTextColor),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: kSubtleTextColor),
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: kSubtleTextColor),
              color: kLightSurfaceColor,
              onSelected: (String value) {
                if (value == 'reload') {
                  Provider.of<ChatRoomController>(context, listen: false)
                      .reloadConversation();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'reload',
                  child: Text('Muat ulang percakapan', style: TextStyle(color: kTextColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat.yMMMMEEEEd('id_ID').format(date),
            style: const TextStyle(
              color: kSubtleTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

enum BubblePosition { single, first, middle, last }

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final User? currentUser;

  const _MessageList({required this.scrollController, required this.currentUser});

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatRoomController>();
    final messages = controller.messages;
    final User safeCurrentUser = controller.currentUser ?? User(username: 'Self');
    final openStoryCallback = (context.findAncestorStateOfType<_ChatRoomPageState>())!._openStoryFromChat;

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.sender.id == safeCurrentUser.id;

        final bool isFirst = index == messages.length - 1 ||
            messages[index + 1].sender.id != message.sender.id;
        final bool isLast =
            index == 0 || messages[index - 1].sender.id != message.sender.id;

        BubblePosition position;
        if (isFirst && isLast) {
          position = BubblePosition.single;
        } else if (isFirst) {
          position = BubblePosition.first;
        } else if (isLast) {
          position = BubblePosition.last;
        } else {
          position = BubblePosition.middle;
        }

        final bool showDateSeparator = index == messages.length - 1 ||
            !_isSameDay(
                message.timestamp, messages[index + 1].timestamp);

        return Column(
          children: [
            if (showDateSeparator) _DateSeparator(date: message.timestamp),
            _MessageBubble(
              message: message,
              isMe: isMe,
              position: position,
              currentUser: safeCurrentUser,
              onStoryThumbnailTap: openStoryCallback,
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final BubblePosition position;
  final User currentUser;
  final Function(ChatMessage) onStoryThumbnailTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.position,
    required this.currentUser,
    required this.onStoryThumbnailTap,
  });

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return Text("➤ Video (belum didukung)", style: TextStyle(color: isMe ? kSentTextColor : kTextColor.withOpacity(0.8)));
      case MessageType.file:
        return Text("➤ File (belum didukung)", style: TextStyle(color: isMe ? kSentTextColor : kTextColor.withOpacity(0.8)));
      case MessageType.text:
      default:
        return Text(message.text ?? '',
            style: TextStyle(
                color: isMe ? kSentTextColor : kTextColor,
                fontSize: 16,
                height: 1.3));
    }
  }

  // BARU: Konten Khusus untuk Story Response
  Widget _buildStoryResponseContent(BuildContext context) {
    return GestureDetector(
      onTap: () => onStoryThumbnailTap(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.respondedStoryMediaUrl != null)
            Container(
              constraints: const BoxConstraints(maxHeight: 100, maxWidth: 200),
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gambar media story yang ditanggapi
                    Image.network(
                      message.respondedStoryMediaUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image, color: kSubtleTextColor))),
                    ),
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Cerita', style: TextStyle(color: kSentTextColor, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Teks respons
          Text(
            message.text ?? 'Tanggapan cerita',
            style: TextStyle(
              color: isMe ? kSentTextColor : kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
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
                return const Center(child: CircularProgressIndicator());
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
    return DateFormat.Hm('id_ID').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final showSenderInfo = !isMe && (position == BubblePosition.first || position == BubblePosition.single);
    final showTimestamp = position == BubblePosition.last || position == BubblePosition.single;

    final Radius cornerRadius = const Radius.circular(18);
    final Radius flatRadius = const Radius.circular(4);

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: isMe ? cornerRadius : (position == BubblePosition.first || position == BubblePosition.single ? cornerRadius : flatRadius),
      topRight: isMe ? (position == BubblePosition.first || position == BubblePosition.single ? cornerRadius : flatRadius) : cornerRadius,
      bottomLeft: isMe ? cornerRadius : (position == BubblePosition.last || position == BubblePosition.single ? cornerRadius : flatRadius),
      bottomRight: isMe ? (position == BubblePosition.last || position == BubblePosition.single ? cornerRadius : flatRadius) : cornerRadius,
    );

    final bool isStoryResponse = message.isStoryResponse; // <-- DETEKSI

    return Container(
      margin: EdgeInsets.only(
        top: 2,
        bottom: position == BubblePosition.last || position == BubblePosition.single ? 10 : 2,
        left: isMe ? 0 : 8,
        right: isMe ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderInfo)
            Padding(
              padding: const EdgeInsets.only(left: 46, bottom: 4),
              child: Text(
                message.sender.fullName ?? message.sender.username,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kSubtleTextColor,
                ),
              ),
            ),

          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && (position == BubblePosition.last || position == BubblePosition.single))
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: message.sender.profilePictureUrl != null
                      ? NetworkImage(message.sender.profilePictureUrl!)
                      : null,
                )
              else if (!isMe)
                const SizedBox(width: 32),

              const SizedBox(width: 8),

              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: isStoryResponse
                    ? const EdgeInsets.all(12)
                    : message.type == MessageType.text
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                    : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isMe ? kSentBubbleColor : kReceivedBubbleColor,
                  borderRadius: borderRadius,
                  // Tambahkan highlight border untuk Story Response yang diterima
                  border: isStoryResponse && !isMe
                      ? Border.all(color: Colors.blueAccent.shade200, width: 2)
                      : null,
                ),
                child: isStoryResponse
                    ? _buildStoryResponseContent(context) // Tampilkan bubble story
                    : _buildMessageContent(context),      // Tampilkan bubble biasa
              ),
            ],
          ),

          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 2, left: 40),
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: kSubtleTextColor,
                ),
              ),
            ),
        ],
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Panggil controller untuk mengirim pesan
    Provider.of<ChatRoomController>(context, listen: false).sendMessage(text);

    _textController.clear();
    // Asumsi ada metode _scrollToBottom() di parent widget atau logic scroll otomatis
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.read<ChatRoomController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8.0),
      decoration: BoxDecoration(
          color: kLightSurfaceColor,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: _attachIconKey,
            icon: const Icon(Icons.add, color: kSubtleTextColor, size: 28,),
            onPressed: () {
              final RenderBox renderBox =
              _attachIconKey.currentContext!.findRenderObject() as RenderBox;
              final size = renderBox.size;
              final position = renderBox.localToGlobal(Offset.zero);

              final chatController = context.read<ChatRoomController>();

              Navigator.of(context).push(
                _FadeSlideUpRoute(
                  buttonPosition: position,
                  buttonSize: size,
                  page: ChangeNotifierProvider.value(
                    value: chatController,
                    child: const _AttachmentPopupMenu(),
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kReceivedBubbleColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: kTextColor),
                decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: kSubtleTextColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12)
                ),
                maxLines: 5,
                minLines: 1,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (_textController.text.trim().isNotEmpty)
            FloatingActionButton.small(
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  chatController.sendMessage(_textController.text);
                  _textController.clear();
                  setState(() {});
                }
              },
              backgroundColor: kSentBubbleColor,
              elevation: 0,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20,),
            ),
        ],
      ),
    );
  }
}

class _ChatRoomSkeletonLoader extends StatelessWidget {
  const _ChatRoomSkeletonLoader();

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
          color: kLightSurfaceColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Gagal Terhubung',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Terdapat masalah pada jaringan Anda. Klik tombol muat ulang untuk mencoba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: kSubtleTextColor),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSentBubbleColor,
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
          ],
        ),
      ),
    );
  }
}