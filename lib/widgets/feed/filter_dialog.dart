// lib/widgets/feed/filter_dialog.dart
import 'package:flutter/material.dart';

class FilterDialog extends StatelessWidget {
  const FilterDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          SizedBox(height: 20),
          _buildTitle(),
          SizedBox(height: 24),
          _buildFilterOption(
            context,
            Icons.trending_up_rounded,
            'Most Popular',
            () => Navigator.pop(context),
          ),
          _buildFilterOption(
            context,
            Icons.access_time_rounded,
            'Most Recent',
            () => Navigator.pop(context),
          ),
          _buildFilterOption(
            context,
            Icons.favorite_rounded,
            'Most Liked',
            () => Navigator.pop(context),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Filter & Sort',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.grey[900],
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
