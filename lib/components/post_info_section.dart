// lib/components/post_info_section.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/models/user_model.dart';
import 'package:portal_si/widgets/likers_bottom_sheet.dart';
import 'package:portal_si/models/liker_model.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/services/post_service.dart';
import 'package:portal_si/utils/navigation_helper.dart';
import 'package:portal_si/helper/time_helper.dart'; // Pastikan path ini benar

class PostInfoSection extends StatefulWidget {
  final Post post;

  const PostInfoSection({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostInfoSection> createState() => _PostInfoSectionState();
}

class _PostInfoSectionState extends State<PostInfoSection> {
  late Future<List<Liker>> _likersFuture;

  @override
  void initState() {
    super.initState();
    _fetchLikers();
  }

  void _fetchLikers() {
    if (widget.post.likesCount > 0) {
      _likersFuture = PostService().getPostLikers(widget.post.id);
    } else {
      _likersFuture = Future.value([]);
    }
  }

  @override
  void didUpdateWidget(covariant PostInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.likesCount != oldWidget.post.likesCount) {
      setState(() {
        _fetchLikers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLikesInfo(),
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  TextSpan(
                      text: widget.post.user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        // Langsung kirim seluruh objek 'widget.post.user'
                        NavigationHelper.navigateToProfile(context, widget.post.user);
                      }
                  ),
                  TextSpan(text: ' ${widget.post.caption}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            timeAgoFromDate(widget.post.createdAt.toIso8601String()),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesInfo() {
    if (widget.post.likesCount == 0) {
      return const Text('Jadilah yang pertama menyukai ini', style: TextStyle(color: Colors.grey));
    }

    return FutureBuilder<List<Liker>>(
      future: _likersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty) {
          final firstLiker = snapshot.data!.first;

          return Row(
            children: [
              CircularAvatarFetcher(
                radius: 10,
                userId: firstLiker.userId,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                    children: [
                      const TextSpan(text: 'Disukai oleh '),
                      TextSpan(
                          text: firstLiker.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            // Buat objek User sederhana dari data Liker yang ada
                            final userToNavigate = User(
                              id: firstLiker.userId,
                              username: firstLiker.username,
                              // Asumsi model Liker Anda juga memiliki properti ini
                              profilePictureUrl: firstLiker.profilePictureUrl,
                              fullName: firstLiker.fullName,
                            );

                            // Kirim objek User yang baru dibuat ke fungsi navigasi
                            NavigationHelper.navigateToProfile(context, userToNavigate);
                          }
                      ),
                      if (widget.post.likesCount > 1)
                        TextSpan(
                            text: ' dan ${widget.post.likesCount - 1} lainnya',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => LikersBottomSheet(postId: widget.post.id),
                              );
                            }
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return Text('${widget.post.likesCount} suka', style: const TextStyle(fontWeight: FontWeight.bold));
      },
    );
  }
}