import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/websocket_provider.dart';

/// Widget to show connection status indicator
class WebSocketStatusIndicator extends StatelessWidget {
  const WebSocketStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: webSocketProvider.isConnected ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}

/// Widget to show notification badge
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int? count;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        final notificationCount =
            count ?? webSocketProvider.unreadNotifications;

        if (notificationCount <= 0) {
          return this.child;
        }

        return Stack(
          children: [
            this.child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  notificationCount > 99 ? '99+' : notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget to show online status indicator
class OnlineStatusIndicator extends StatelessWidget {
  final int userId;
  final double size;

  const OnlineStatusIndicator({
    Key? key,
    required this.userId,
    this.size = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        final isOnline = webSocketProvider.isUserOnline(userId);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.grey,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

/// Widget to show real-time like count
class LiveLikeCount extends StatelessWidget {
  final int postId;
  final int initialCount;
  final TextStyle? textStyle;

  const LiveLikeCount({
    Key? key,
    required this.postId,
    required this.initialCount,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        // In a real implementation, you would track the like count per post
        // For now, we'll just show the initial count
        return Text(
          initialCount.toString(),
          style: textStyle,
        );
      },
    );
  }
}

/// Widget to show real-time comment count
class LiveCommentCount extends StatelessWidget {
  final int postId;
  final int initialCount;
  final TextStyle? textStyle;

  const LiveCommentCount({
    Key? key,
    required this.postId,
    required this.initialCount,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        // In a real implementation, you would track the comment count per post
        // For now, we'll just show the initial count
        return Text(
          initialCount.toString(),
          style: textStyle,
        );
      },
    );
  }
}

/// Widget to show story ring with real-time updates
class StoryRing extends StatelessWidget {
  final int userId;
  final String imageUrl;
  final VoidCallback? onTap;
  final double size;

  const StoryRing({
    Key? key,
    required this.userId,
    required this.imageUrl,
    this.onTap,
    this.size = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        // Check if there are new stories for this user
        final hasNewStories = webSocketProvider.recentStories
            .any((story) => story['user_id'] == userId);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNewStories
                  ? const LinearGradient(
                      colors: [Colors.purple, Colors.orange, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasNewStories ? null : Colors.grey[300],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: (size - 8) / 2,
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget to show real-time message preview
class LiveMessagePreview extends StatelessWidget {
  final int roomId;
  final String type; // 'direct' or 'group'
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isRead;

  const LiveMessagePreview({
    Key? key,
    required this.roomId,
    required this.type,
    this.lastMessage,
    this.lastMessageTime,
    this.isRead = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        // In a real implementation, you would get the latest message from the stream
        // For now, we'll show the provided last message
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastMessage ?? 'No messages',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: isRead ? Colors.grey[600] : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (lastMessageTime != null)
                Text(
                  _formatTime(lastMessageTime!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Widget to show connection status with retry button
class WebSocketConnectionStatus extends StatelessWidget {
  const WebSocketConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        if (webSocketProvider.isConnected) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                'Connected',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Disconnected',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => webSocketProvider.reconnect(),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
