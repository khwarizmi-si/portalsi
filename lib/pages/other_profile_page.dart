import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/models/user_model.dart';
import 'package:portal_si/pages/portfolio_pages.dart';
import 'package:portal_si/pages/post_detail.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../components/bottom_navigation.dart';
import '../components/video_thumbnail_widget.dart';
import '../providers/navigation_provider.dart';
import '../services/user_service.dart'; // Hanya import service yang benar
import '../services/follow_service.dart'; // Hanya import service yang benar
import '../utils/navigation_helper.dart';
import 'chat_room.dart';
import 'followers_following_page.dart';

class OtherProfilePage extends StatefulWidget {
  final String username;

  const OtherProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> with TickerProviderStateMixin {
  User? _profileData;

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowActionLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pisahkan instance service agar lebih rapi
  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileService.getOtherProfile(widget.username);
      final followStatus = await _followService.getFollowStatus(widget.username);


      if (mounted) {
        setState(() {
          _profileData = profile;
          _isFollowing = followStatus['isFollowing'] ?? false;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat profil: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollowAction() async {
    if (_isFollowActionLoading || _profileData == null) return;
    setState(() => _isFollowActionLoading = true);

    try {
      final username = _profileData!.username;
      final originalFollowersCount = _profileData!.followersCount;
      final originalFollowingState = _isFollowing;

      // Optimistic UI update
      setState(() {
        _isFollowing = !_isFollowing;
        _profileData = _profileData!.copyWith(
          followersCount: originalFollowersCount + (_isFollowing ? 1 : -1),
        );
      });

      bool success = _isFollowing
          ? await _followService.followUser(username)
          : await _followService.unfollowUser(username);

      if (!success && mounted) {
        // Revert UI if API call fails

        setState(() {
          _isFollowing = originalFollowingState;
          _profileData = _profileData!.copyWith(followersCount: originalFollowersCount);
        });
      }

    } catch (e) {
      await _loadAllData();
    } finally {
      if (mounted) setState(() => _isFollowActionLoading = false);
    }
  }

  void _navigateToFollowersFollowing(int initialTab) async { // <-- Tambahkan async
    if (_profileData == null || _profileData!.id == null) return;

    // --- PERUBAHAN UTAMA DI SINI ---
    // Kita akan menunggu (await) hasil dari halaman yang dibuka
    final result = await Navigator.push<Map<dynamic, dynamic>>( // <-- Tambahkan await dan tipe data
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: _profileData!.id!,
          initialTab: initialTab,
        ),
      ),
    );

    // Jika ada data yang dikembalikan (artinya user mengklik profil)
    // dan halaman ini masih aktif, maka jalankan navigasi.
    if (result != null && mounted) {
      NavigationHelper.navigateToProfile(
        context,
        Map<String, dynamic>.from(result), // Lakukan cast di sini
      );
    }
    // --- Batas Perubahan ---
  }

  void _navigateToChatRoom() {
    // Pastikan data profil tidak null sebelum navigasi
    if (_profileData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(user: _profileData!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // BUNGKUS DENGAN PADDING DI SINI
    return Padding(
      // Beri jarak di bawah setinggi navigasi bar + margin-nya
      // Anda bisa sesuaikan nilai 100.0 ini jika perlu
      padding: const EdgeInsets.only(bottom: 100.0),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
        },
        child: Material(
          color: Colors.transparent,
          // Tambahkan clipRRect agar sudutnya melengkung, serasi dengan nav bar
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // --- PERUBAHAN DI SINI ---
    // Jika sedang loading, tampilkan widget skeleton
    if (_isLoading) return const ProfilePageSkeleton();
    // return const ProfilePageSkeleton();
    // --- Batas Perubahan ---

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(onPressed: _loadAllData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileSection()),
            _buildPostGridSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 1,
      // 2. Perbarui aksi tombol kembali di SliverAppBar
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Panggil provider untuk menyembunyikan overlay
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
        },
      ),
      title: Text(
        _profileData?.username ?? 'Profil',
        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'cover_${_profileData?.username ?? ''}',
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_profileData?.profilePictureUrl ?? 'https://via.placeholder.com/400'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_profileData == null) return const SizedBox.shrink();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: 'profile_${_profileData!.username}',
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileData!.profilePictureUrl != null && _profileData!.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(_profileData!.profilePictureUrl!)
                      : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(_profileData!.postsCount.toString(), 'Postingan', null),
                    _buildStatItem(_profileData!.followersCount.toString(), 'Pengikut', () => _navigateToFollowersFollowing(0)),
                    _buildStatItem(_profileData!.followingCount.toString(), 'Mengikuti', () => _navigateToFollowersFollowing(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _profileData!.fullName ?? _profileData!.username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (_profileData!.bio != null && _profileData!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _profileData!.bio!,
              style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
            ),
          ],
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isFollowActionLoading ? null : () { /* Panggil _handleFollowAction */ },
                style: ElevatedButton.styleFrom(
                  // 1. Atur warna utama dan bayangan menjadi transparan jika BUKAN sedang mengikuti
                  //    agar gradien dari Container di child bisa terlihat.
                  backgroundColor: _isFollowing ? Colors.grey[200] : Colors.transparent,
                  shadowColor: _isFollowing ? Colors.black.withOpacity(0.2) : Colors.transparent,

                  // Properti lain tetap sama
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  elevation: _isFollowing ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: _isFollowing ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
                  ),
                  padding: EdgeInsets.zero, // 2. Atur padding tombol ke nol, karena kita akan atur di Container
                ),
                child: Ink(
                  // 3. Gunakan Ink atau Container untuk dekorasi gradien
                  decoration: BoxDecoration(
                    gradient: _isFollowing
                        ? null // Tidak ada gradien saat sudah 'mengikuti'
                        : LinearGradient(
                      colors: [
                        Colors.amber.shade600,
                        Colors.orange.shade800,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // 4. Atur padding di sini, di dalam Container
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: _isFollowActionLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        // Pastikan warna loading indicator sesuai dengan background-nya
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      _isFollowing ? 'Mengikuti' : 'Ikuti',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                // --- PERUBAHAN UTAMA DI SINI ---
                onPressed: _navigateToChatRoom, // Panggil fungsi navigasi
                // --- Batas Perubahan ---
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Pesan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: const Color(0x83B98946), offset: const Offset(0, 3), blurRadius: 10, spreadRadius: -2),

                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_profileData != null) {
                      Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: PortfolioPage(user: _profileData!)));

                      HapticFeedback.lightImpact();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC87B),
                    foregroundColor: Colors.grey[800],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lihat Portofolio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),

                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatItem(String count, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPostGridSliver() {
    if (_profileData == null || _profileData!.recentPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(padding: EdgeInsets.symmetric(vertical: 50.0), child: Text('Belum ada postingan.')),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final post = _profileData!.recentPosts[index];

            // Widget untuk menampilkan media (gambar atau thumbnail video)
            Widget mediaDisplay;
            if (post.isVideo) {
              // Jika video, gunakan VideoThumbnailWidget
              mediaDisplay = VideoThumbnailWidget(videoUrl: post.mediaUrl);
            } else {
              // Jika gambar, gunakan Image.network seperti biasa
              mediaDisplay = Image.network(post.mediaUrl, fit: BoxFit.cover);
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetail(postId: post.postId),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'post_hero_${post.postId}',
                  child: mediaDisplay, // <-- GUNAKAN WIDGET mediaDisplay DI SINI
                ),
              ),
            );
          },
          childCount: _profileData!.recentPosts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }

  void _showImageDetail(SimplePost post, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () { // Using a block body for clarity
                Navigator.pop(context);
                // FIX: Replace 'mainPost.user' with the correct variable '_profileData!'
                if (_profileData != null) {
                  NavigationHelper.navigateToProfile(
                      context, _profileData!.toJson());
                }
              },
            ),
            title: Text(post.caption ?? '', style: const TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Hero(
              tag: 'post_${post.postId}_$index',
              child: InteractiveViewer(child: Image.network(post.mediaUrl, fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }
}

extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? bio,
    String? profilePictureUrl,
    bool? isVerified,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<SimplePost>? recentPosts,

  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      followersCount: followersCount ?? this.followersCount,
      email: this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      recentPosts: recentPosts ?? this.recentPosts,

    );
  }
}
// lib/pages/other_profile_page.dart

/// Widget skeleton loading yang bisa di-scroll.
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // 1. Kerangka untuk Cover
            Container(
              height: 250,
              color: Colors.white,
            ),

            // 2. Kerangka untuk Konten Profil
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Bagian Avatar & Statistik ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatSkeleton(),
                            _buildStatSkeleton(),
                            _buildStatSkeleton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Bagian Nama & Bio ---
                  _buildLineSkeleton(height: 18, width: 200),
                  const SizedBox(height: 12),
                  _buildLineSkeleton(height: 16),
                  const SizedBox(height: 24),

                  // --- Bagian Tombol Aksi ---
                  Row(
                    children: [
                      Expanded(child: _buildLineSkeleton(height: 48, radius: 10)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLineSkeleton(height: 48, radius: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4), // Sedikit spasi tambahan sebelum grid

            // --- 3. PERUBAHAN UTAMA: GUNAKAN GridView.count ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.count(
                crossAxisCount: 3, // Jumlah kolom

                // --- KONTROL PENUH JARAK (GAP) DI SINI ---
                crossAxisSpacing: 16, // Jarak horizontal
                mainAxisSpacing: 16,  // Jarak vertikal
                // --- Batas Kontrol Jarak ---

                shrinkWrap: true, // Wajib agar GridView di dalam Column tahu ukurannya
                physics: const NeverScrollableScrollPhysics(), // Wajib agar tidak bisa di-scroll
                children: List.generate(3, (index) => _buildGridItemSkeleton()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk membuat satu item grid
  Widget _buildGridItemSkeleton() {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Helper untuk membuat kerangka statistik
  Widget _buildStatSkeleton() {
    return Column(
      children: [
        _buildLineSkeleton(width: 45, height: 12),
        const SizedBox(height: 8),
        _buildLineSkeleton(width: 45, height: 12),
      ],
    );
  }

  // Helper utama untuk membuat satu baris/kotak kerangka
  Widget _buildLineSkeleton({double? width, double height = 16, double radius = 8}) {
    return Container(
      width: width ?? double.infinity,
      // margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.only(bottom: 40),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}