import 'package:flutter/material.dart';
import '../../services/follow_service.dart';
import 'package:flutter/foundation.dart';

class CacheMonitorWidget extends StatefulWidget {
  const CacheMonitorWidget({Key? key}) : super(key: key);

  @override
  _CacheMonitorWidgetState createState() => _CacheMonitorWidgetState();
}

class _CacheMonitorWidgetState extends State<CacheMonitorWidget> {
  final FollowService _followService = FollowService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '📊 Cache Monitor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Print Stats',
                  Colors.blue,
                  () => _followService.printCacheStats(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Clean Cache',
                  Colors.orange,
                  () => _followService.cleanExpiredCache(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Clear All',
                  Colors.red,
                  () => _followService.clearCache(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Refresh',
                  Colors.green,
                  () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '💡 Tips:',
            style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '• Check console for detailed cache stats\n'
            '• High hit rate = good performance\n'
            '• Clean cache periodically\n'
            '• Remove this widget in production',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}

// Extension untuk mudah debugging
extension PostHeaderDebug on Widget {
  Widget withCacheMonitor() {
    return Column(
      children: [
        this,
        // Show only in debug mode
        if (kDebugMode)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CacheMonitorWidget(),
          ),
      ],
    );
  }
}
