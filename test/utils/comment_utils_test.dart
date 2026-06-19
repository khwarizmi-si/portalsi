// Unit tests for CommentUtils — pure logic, no plugin/Firebase init required.
// Replaces the stale default "Counter increments" widget test that referenced
// UI that does not exist in this app.

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_si/utils/comment_utils.dart';

void main() {
  group('CommentUtils.timeAgo', () {
    test('returns "Baru saja" for differences under 10 seconds', () {
      // Arrange
      final date = DateTime.now().subtract(const Duration(seconds: 3));

      // Act
      final result = CommentUtils.timeAgo(date);

      // Assert
      expect(result, 'Baru saja');
    });

    test('returns seconds bucket between 10 and 60 seconds', () {
      final date = DateTime.now().subtract(const Duration(seconds: 30));

      final result = CommentUtils.timeAgo(date);

      expect(result, endsWith('d lalu'));
    });

    test('returns minutes bucket under one hour', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));

      final result = CommentUtils.timeAgo(date);

      expect(result, '5m lalu');
    });

    test('returns hours bucket under one day', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));

      final result = CommentUtils.timeAgo(date);

      expect(result, '3j lalu');
    });

    test('returns days bucket under one week', () {
      final date = DateTime.now().subtract(const Duration(days: 4));

      final result = CommentUtils.timeAgo(date);

      expect(result, '4h lalu');
    });
  });

  group('CommentUtils.generateTempId / isTemporary', () {
    test('generateTempId always produces a negative id', () {
      final id = CommentUtils.generateTempId();

      expect(id, lessThan(0));
    });
  });
}
