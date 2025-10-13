// lib/pages/dashboard_page.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/pages/portfolio_page.dart';
import 'package:portal_si/pages/story_view_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

// Halaman & Komponen UI
import 'package:portal_si/components/post_card.dart';
import 'package:portal_si/components/story_section.dart';
import 'package:portal_si/widgets/comment_section.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/pages/message_list_page.dart';
import 'package:portal_si/pages/announcement_list_page.dart';

// State Management & Model
import '../app_state.dart';
import '../components/verified_badge.dart';
import '../controllers/home_controller.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../providers/navigation_provider.dart';
import '../providers/upload_provider.dart';
import '../services/follow_service.dart';
import '../services/group_service.dart';
import '../services/story_service.dart';
import '../utils/gradient_generator.dart';
import '../utils/user_provider.dart';
import '../models/post_model.dart';
import '../models/announcement_model.dart';
import '../models/story_model.dart';
import '../providers/scroll_provider.dart';

// Servis & Helper
import '../services/notification_service.dart';
import '../utils/navigation_helper.dart';
import 'group_chat_room_page.dart';
import 'main_scaffold.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _HomePageState();
}

class _HomePageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin{
  final ScrollController _scrollController = ScrollController();
  int _unreadNotificationCount = 0;
  final GlobalKey _notificationIconKey = GlobalKey();
  final GlobalKey _anncIconKey = GlobalKey();
  final GlobalKey _msgIconKey = GlobalKey();

  final GlobalKey _announcementButtonKey = GlobalKey();
  final GlobalKey _portfolioButtonKey = GlobalKey();

  // TAMBAHKAN: State untuk menyimpan hasil pre-fetch gradien
  final Map<int, List<Color>> _prefetchedGradients = {};
  // TAMBAHKAN: Set untuk melacak story yang sudah di-prefetch agar tidak duplikat
  final Set<int> _processedStoryIds = {};

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        bool isDialogVisible = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer(const Duration(milliseconds: 50), () {
              if (mounted) {
                setDialogState(() {
                  isDialogVisible = true;
                });
              }
            });

            return WillPopScope(
              onWillPop: () async => false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isDialogVisible ? 1.0 : 0.0,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    scale: isDialogVisible ? 1.0 : 0.8,
                    child: Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- PERUBAHAN WARNA & IKON ---
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.redAccent.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.policy_rounded, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Akses Terbatas",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // --- PERUBAHAN ISI KONTEN ---
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.5,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(text: 'Fitur ini hanya tersedia untuk peran '),
                                  TextSpan(
                                    text: 'Teacher',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                                  ),
                                  const TextSpan(text: ' dan '),
                                  TextSpan(
                                    text: 'Parent',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                                  ),
                                  const TextSpan(text: ' untuk menjaga privasi dan memastikan komunikasi yang terstruktur.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Jika Anda merasa ada kesalahan pada peran akun Anda, silakan hubungi administrator.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setDialogState(() => isDialogVisible = false);
                                Timer(const Duration(milliseconds: 200), () {
                                  if (mounted) Navigator.of(context).pop();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber.shade600, Colors.orange.shade800],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Saya Mengerti',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
      final direction = _scrollController.position.userScrollDirection;

      if (direction == ScrollDirection.reverse) {
        scrollProvider.setScrolled(true);
      }
      else if (direction == ScrollDirection.forward) {
        scrollProvider.setScrolled(false);
      }

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Provider.of<HomeController>(context, listen: false).fetchMorePosts();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScrollProvider>(context, listen: false).setDashboardController(_scrollController);
      Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();

      // --- REMOVED --- Hapus listener untuk prefetch
      // final homeController = Provider.of<HomeController>(context, listen: false);
      // homeController.addListener(_onHomeControllerUpdate);
      // homeController.loadDashboardData();

      // *** MODIFIED *** Panggil langsung tanpa listener
      Provider.of<HomeController>(context, listen: false).loadDashboardData();
    });
    _loadNotificationCount();
  }

  // Tambahkan method ini di dalam class _HomePageState
  Widget _buildErrorStateWidget(BuildContext context, HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon untuk representasi visual
          Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),

          // Judul pesan error
          const Text(
            "Oops, Gagal Terhubung",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Deskripsi yang lebih ramah
          Text(
            "Sepertinya ada masalah dengan koneksi internet Anda. Silakan periksa kembali dan coba lagi.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Tombol "Coba Lagi" dengan desain yang sesuai
          ElevatedButton(
            onPressed: () {
              // Panggil fungsi refresh yang sudah ada
              Provider.of<HomeController>(context, listen: false).refreshDashboardData();
              Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero, // Hapus padding default
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8, // Beri sedikit bayangan agar menonjol
              shadowColor: Colors.orange.withOpacity(0.4),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade800],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _onHomeControllerUpdate() {
    final controller = Provider.of<HomeController>(context, listen: false);
    // Cek jika data sudah ada dan belum diproses
    if (!controller.isLoading && controller.stories.isNotEmpty) {
      _prefetchStoryGradients(controller.stories);
    }
  }

  void _prefetchStoryGradients(List<UserWithStories> users) {
    for (var user in users) {
      // Hanya proses jika user ini belum pernah diproses sebelumnya
      if (user.stories.isNotEmpty && !_processedStoryIds.contains(user.userId)) {

        // Tandai user ini sudah diproses
        _processedStoryIds.add(user.userId);

        final firstStory = user.stories.first;
        final imageUrl = firstStory.mediaUrl ?? firstStory.musicAlbumArtUrl;

        // Panggil helper secara async
        generateGradientColors(imageUrl).then((colors) {
          if (mounted && colors.isNotEmpty) {
            setState(() {
              // Simpan hasilnya ke Map menggunakan userId sebagai kunci
              _prefetchedGradients[user.userId] = colors;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // Provider.of<HomeController>(context, listen: false).removeListener(_onHomeControllerUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isSpecial = false,
    Key? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSpecial)
                Positioned(
                  top: 5,
                  left: -4,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUserRole = userProvider.currentUser?.role;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAccessItem(
                icon: Icons.group_outlined,
                label: 'Group SI',
                isSpecial: true,
                onTap: () async {
                  final allowedRoles = ['teacher', 'parent'];

                  if (currentUserRole != null && allowedRoles.contains(currentUserRole)) {
                    HapticFeedback.lightImpact();
                    try {
                      final groups = await GroupService().getParentGroups();
                      if (!mounted) return;

                      if (groups.length == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatRoomPage(group: groups.first),
                          ),
                        );
                      } else if (groups.length > 1) {
                        _showGroupSelectionDialog(context, groups);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tidak ada grup yang ditemukan.')),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal memuat grup: $e')),
                      );
                    }
                  } else {
                    HapticFeedback.heavyImpact();
                    mainScaffoldKey.currentState?.triggerShake();
                    _showPermissionDeniedDialog();
                  }
                },
              ),
              _buildQuickAccessItem(
                icon: Icons.storefront_outlined,
                label: 'Marketplace',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Provider.of<NavigationProvider>(context, listen: false).navigateToTab(3);
                },
              ),
              _buildQuickAccessItem(
                key: _portfolioButtonKey,
                icon: Icons.school_outlined,
                label: 'Portfolio',
                onTap: () {
                  HapticFeedback.lightImpact();
                  final RenderBox renderBox = _portfolioButtonKey.currentContext!.findRenderObject() as RenderBox;
                  final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                  Navigator.push(context, ScaleFromPositionRoute(widget: const PortfolioPage(), originOffset: originOffset));
                },
              ),
              _buildQuickAccessItem(
                key: _announcementButtonKey,
                icon: Icons.campaign_outlined,
                label: 'Pengumuman',
                onTap: () {
                  HapticFeedback.lightImpact();
                  final RenderBox renderBox = _announcementButtonKey.currentContext!.findRenderObject() as RenderBox;
                  final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                  Navigator.push(context, ScaleFromPositionRoute(widget: const AnnouncementListPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGroupSelectionDialog(BuildContext context, List<Group> groups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pilih Grup', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                        ? NetworkImage(group.avatarUrl!)
                        : null,
                    child: group.avatarUrl == null || group.avatarUrl!.isEmpty
                        ? const Icon(Icons.group)
                        : null,
                  ),
                  title: Text(group.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatRoomPage(group: group),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService().getNotifications();
      final unreadCount = notifications
          .where((notif) => notif['is_read'] == false || notif['is_read'] == 0)
          .length;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notification count in HomePage: $e');
    }
  }


  void _showCommentSheet(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: CommentSection(
            postId: post.id,
            initialComments: post.comments,
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: max(0.0, MediaQuery.of(context).padding.top - 25),
          bottom: 5
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 18),
          )
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Portal SI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 26)),
        actions: [
          IconButton(
            key: _anncIconKey,
            onPressed: () {
              HapticFeedback.lightImpact();
              final RenderBox renderBox = _anncIconKey.currentContext!.findRenderObject() as RenderBox;
              final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
              Navigator.push(context, ScaleFromPositionRoute(widget: const AnnouncementListPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
            },
            icon: const Icon(Icons.campaign_outlined, color: Colors.black),
            tooltip: 'List Pengumuman',
          ),
          Stack(
            children: [
              IconButton(
                key: _notificationIconKey,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final RenderBox renderBox = _notificationIconKey.currentContext!.findRenderObject() as RenderBox;
                  final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                  Navigator.push(context, ScaleFromPositionRoute(widget: const NotificationPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
                },
                icon: const Icon(Icons.notifications, color: Colors.black),
                tooltip: 'Notifikasi',
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(_unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            key: _msgIconKey,
            onPressed: () {
              HapticFeedback.lightImpact();
              final RenderBox renderBox = _msgIconKey.currentContext!.findRenderObject() as RenderBox;
              final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
              Navigator.push(context, ScaleFromPositionRoute(widget: const MessageListPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
            },
            icon: const Icon(Icons.send_outlined, color: Colors.black),
            tooltip: 'Pesan',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildUploadProgressCard(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, child) {
        if (!uploadProvider.isUploading || uploadProvider.currentTask == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final task = uploadProvider.currentTask!;
        final progress = uploadProvider.uploadProgress;
        final percentage = (progress * 100).toStringAsFixed(0);

        // --- 👇 PERUBAHAN DI SINI 👇 ---
        final String uploadText = task.type == UploadType.story
            ? "Mengirim story..."
            : "Mengirim postingan...";

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    task.thumbnail,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uploadText, // <-- Gunakan teks dinamis
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("$percentage%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Batalkan Unggahan?"),
                        content: const Text("Anda yakin ingin membatalkan proses unggah ini?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("Lanjutkan"),
                          ),
                          TextButton(
                            onPressed: () {
                              uploadProvider.cancelUpload();
                              Navigator.pop(dialogContext);
                            },
                            child: const Text("Batalkan", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // Kondisi loading awal, tidak berubah
        if (controller.isLoading && controller.feedItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✨ --- PERUBAHAN UTAMA DI SINI --- ✨
        // Jika ada error, tampilkan widget error yang baru
        if (controller.errorMessage != null) {
          return RefreshIndicator(
            onRefresh: () async {
              // Fungsi refresh yang sama dengan yang ada di body utama
              await Future.wait([
                Provider.of<HomeController>(context, listen: false).refreshDashboardData(),
                Provider.of<UserProvider>(context, listen: false).fetchCurrentUser(),
              ]);
            },
            // Bungkus dengan CustomScrollView agar RefreshIndicator berfungsi
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, // Penting agar konten tetap di tengah
                  child: _buildErrorStateWidget(context, controller),
                )
              ],
            ),
          );
        }

        // Kondisi jika feed kosong, tidak berubah
        if (controller.feedItems.isEmpty && controller.pinnedPost == null && controller.pinnedAnnouncements.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                Provider.of<HomeController>(context, listen: false).refreshDashboardData(),
                Provider.of<UserProvider>(context, listen: false).fetchCurrentUser(),
              ]);
            },
            child: const CustomScrollView(
              slivers: [
                SliverFillRemaining(child: Center(child: Text('Tidak ada konten untuk ditampilkan.')))
              ],
            ),
          );
        }

        // Tampilan body utama jika tidak ada error, tidak berubah
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              Provider.of<HomeController>(context, listen: false).refreshDashboardData(),
              Provider.of<UserProvider>(context, listen: false).fetchCurrentUser(),
            ]);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                  child: StorySection(
                    stories: controller.stories,
                  )
              ),
              _buildUploadProgressCard(context),
              SliverToBoxAdapter(child: _buildQuickAccessButtons()),
              SliverToBoxAdapter(child: PinnedAnnouncementsSection(announcements: controller.pinnedAnnouncements)),
              _buildPinnedPost(context, controller),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final dynamic item = controller.feedItems[index];
                    final String itemType = item is Map ? item['type'] ?? '' : '';

                    if (itemType == 'post') {
                      final Post post = Post.fromJson(item as Map<String, dynamic>);
                      return PostCard(
                        post: post,
                        onLike: () => controller.toggleLike(post.id),
                        onBookmark: () => controller.toggleBookmark(post.id),
                        onComment: () => _showCommentSheet(context, post),
                        onShare: () {},
                        onProfileTap: () {
                          AppState.navFrom = "dashboard";
                          NavigationHelper.navigateToProfile(context, post.user);
                        },
                      );
                    } else if (itemType == 'suggestion') {
                      final List<dynamic> users = item['users'] ?? [];
                      return SuggestionCard(users: users);
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                  childCount: controller.feedItems.length,
                ),
              ),
              SliverToBoxAdapter(
                child: controller.isFetchingMore
                    ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinnedPost(BuildContext context, HomeController controller) {
    final pinnedPost = controller.pinnedPost;
    if (pinnedPost == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final bool isExpired = DateTime.now().difference(pinnedPost.createdAt).inHours >= 24;
    if (isExpired) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: _PinnedPostCard(
        post: pinnedPost,
        controller: controller,
        onComment: () => _showCommentSheet(context, pinnedPost),
      ),
    );
  }
}

class PinnedAnnouncementsSection extends StatefulWidget {
  final List<Announcement> announcements;
  const PinnedAnnouncementsSection({super.key, required this.announcements});

  @override
  State<PinnedAnnouncementsSection> createState() => _PinnedAnnouncementsSectionState();
}

class _PinnedAnnouncementsSectionState extends State<PinnedAnnouncementsSection> {
  int _currentIndex = 0;
  bool _isSwipingForward = true;
  Timer? _timer;
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcements.isNotEmpty) {
      _handleTimer(widget.announcements.length);
    }
  }

  @override
  void didUpdateWidget(covariant PinnedAnnouncementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.announcements.isNotEmpty) {
      _handleTimer(widget.announcements.length);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTimer(int total) {
    _timer?.cancel();
    if (_isCardExpanded || total <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) _swipe(total, forward: true, fromAutoSwipe: true);
    });
  }

  void _swipe(int total, {required bool forward, bool fromAutoSwipe = false}) {
    setState(() {
      _isSwipingForward = forward;
      _currentIndex = (forward ? _currentIndex + 1 : _currentIndex - 1 + total) % total;
    });
    if (!fromAutoSwipe) _handleTimer(total);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final announcements = widget.announcements;
    final totalAnnouncements = announcements.length;
    if (_currentIndex >= totalAnnouncements) _currentIndex = 0;
    final currentAnnouncement = announcements[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (totalAnnouncements <= 1) return;
              if (details.primaryVelocity! < -100) _swipe(totalAnnouncements, forward: true);
              else if (details.primaryVelocity! > 100) _swipe(totalAnnouncements, forward: false);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(_isSwipingForward ? 1.0 : -1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(child: SlideTransition(position: offsetAnimation, child: child));
              },
              child: AnnouncementCard(
                key: ValueKey<int>(currentAnnouncement.id),
                announcement: currentAnnouncement,
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    _isCardExpanded = isExpanded;
                  });
                  _handleTimer(totalAnnouncements);
                },
              ),
            ),
          ),
          if (totalAnnouncements > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${_currentIndex + 1} dari $totalAnnouncements pengumuman',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            )
        ],
      ),
    );
  }
}

class _PinnedPostCard extends StatelessWidget {
  final Post post;
  final HomeController controller;
  final VoidCallback onComment;

  const _PinnedPostCard({required this.post, required this.controller, required this.onComment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.yellow.shade50, Colors.amber.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.push_pin, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Text("Postingan Disematkan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: PostCard(
              post: post,
              hasCardDecoration: false,
              onLike: () => controller.toggleLike(post.id),
              onBookmark: () {},
              onShare: () {},
              onComment: onComment,
              onProfileTap: () {
                AppState.navFrom = "dashboard";
                NavigationHelper.navigateToProfile(context, post.user);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ScaleFromPositionRoute extends PageRouteBuilder {
  final Widget widget;
  final Offset originOffset;

  ScaleFromPositionRoute({required this.widget, required this.originOffset})
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    opaque: false,
    barrierDismissible: true,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final screenSize = MediaQuery.of(context).size;
      final alignX = (originOffset.dx / screenSize.width) * 2 - 1;
      final alignY = (originOffset.dy / screenSize.height) * 2 - 1;
      final curveAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return ScaleTransition(alignment: Alignment(alignX, alignY), scale: curveAnimation, child: child);
    },
  );
}

class AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final Function(bool) onExpansionChanged;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onExpansionChanged,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleExpand,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF5D6),
              const Color(0xFFFFE7A3).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    AppState.navFrom = "dashboard";
                    final userToNavigate = User(
                      id: widget.announcement.creator.userId,
                      username: widget.announcement.creator.username,
                      fullName: widget.announcement.creator.fullName,
                      isVerified: widget.announcement.creator.isVerified,
                      profilePictureUrl: widget.announcement.creator.profilePictureUrl,
                    );
                    NavigationHelper.navigateToProfile(
                      context,
                      userToNavigate,
                    );
                  },
                  child: CircularAvatarFetcher(
                    radius: 22,
                    userId: widget.announcement.creator.userId,
                  ),
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign_outlined, color: Colors.orange.shade800, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            timeago.format(widget.announcement.createdAt, locale: 'id'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.announcement.creator.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                ),
                                if (widget.announcement.creator.isVerified)
                                  const VerifiedBadge(size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.announcement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _isExpanded ? double.infinity : 0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.announcement.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.announcement.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                      Text(
                        widget.announcement.content,
                        style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final List<dynamic> users;
  const SuggestionCard({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 230,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Disarankan untuk Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                if (user is! Map<String, dynamic> || user['user_id'] == null) {
                  return const SizedBox.shrink();
                }

                return _SuggestionProfileCard(
                  key: ValueKey(user['user_id']),
                  user: user,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionProfileCard extends StatefulWidget {
  final Map<String, dynamic> user;

  const _SuggestionProfileCard({super.key, required this.user});

  @override
  State<_SuggestionProfileCard> createState() => _SuggestionProfileCardState();
}

class _SuggestionProfileCardState extends State<_SuggestionProfileCard> {
  bool _isLoading = false;
  bool _isFollowed = false;
  bool _showShimmer = false;
  bool _isLoadingStory = false;

  final FollowService _followService = FollowService();
  final StoryService _storyService = StoryService();

  Future<void> _toggleFollowStatus() async {
    setState(() => _isLoading = true);

    bool success;
    if (_isFollowed) {
      success = await _followService.unfollowUser(widget.user['user_id']);
    } else {
      success = await _followService.followUser(widget.user['user_id']);
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isFollowed = !_isFollowed;
      });

      if (_isFollowed) {
        setState(() => _showShimmer = true);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            setState(() => _showShimmer = false);
          }
        });
      }
    } else {
      final action = _isFollowed ? "berhenti mengikuti" : "mengikuti";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal $action ${widget.user['username']}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _navigateToStoryView() async {
    if (_isLoadingStory) return;
    setState(() => _isLoadingStory = true);

    // TIDAK PERLU LAGI MENGAMBIL DATA DI SINI.

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => StoryViewPage(
          initialUserId: widget.user['user_id'], // CUKUP KIRIM USER ID
          heroTag: 'story_hero_${widget.user['user_id']}',
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    if (mounted) setState(() => _isLoadingStory = false);
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] ?? 'No Username';
    final fullName = widget.user['full_name'] ?? 'No Name';
    final bool isFollowBack = widget.user['is_follow_back'] ?? false;
    final String buttonText = _isFollowed ? 'Mengikuti' : (isFollowBack ? 'Ikuti Balik' : 'Ikuti');
    final bool isVerified = widget.user['is_verified'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              AppState.navFrom = "dashboard";
              final userToNavigate = User.fromJson(widget.user);
              NavigationHelper.navigateToProfile(context, userToNavigate);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: CircularAvatarFetcher(
                          userId: widget.user['user_id'] as int,
                          radius: 30,
                        ),
                      ),
                      if (_isLoadingStory)
                        const SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const SizedBox(width: 2,),
                      if (isVerified)
                        const VerifiedBadge(size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(fullName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _toggleFollowStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowed ? Colors.grey.shade300 : Colors.transparent,
                      shadowColor: _isFollowed ? Colors.black.withOpacity(0.2) : Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: _isFollowed ? 0 : 2,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _isFollowed
                            ? null
                            : LinearGradient(
                          colors: [
                            Colors.amber.shade600,
                            Colors.orange.shade800,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 88, minHeight: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: _isFollowed ? Colors.black54 : Colors.white,
                          ),
                        )
                            : Text(
                          buttonText,
                          style: TextStyle(
                            color: _isFollowed ? Colors.black54 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (_showShimmer)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.6),
                  period: const Duration(milliseconds: 1000),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}