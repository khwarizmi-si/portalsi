// lib/widgets/feed/feed_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedHeader extends StatelessWidget {
  final TextEditingController searchController;
  final bool isScrolled;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;

  const FeedHeader({
    Key? key,
    required this.searchController,
    required this.isScrolled,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        // boxShadow: isScrolled
        //     ? [
        //         BoxShadow(
        //           color: Colors.black.withOpacity(0.08),
        //           blurRadius: 20,
        //           offset: Offset(0, 4),
        //         ),
        //       ]
        //     : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temukan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Eksplor konten menarik di Portal SI!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: IconButton(
              //     icon: Icon(Icons.tune_rounded, color: Colors.grey[700]),
              //     onPressed: () {
              //       HapticFeedback.lightImpact();
              //       onFilterTap();
              //     },
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 20),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Cari pengguna...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 22,
            ),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: onClearSearch,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: onSearchChanged,
        onSubmitted: onSearchChanged,
      ),
    );
  }
}