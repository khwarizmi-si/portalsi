import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/paginated_story_feed.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/story_service.dart';
import '../utils/secure_storage.dart';
import 'story_content_controller.dart';

class StoryViewController extends ChangeNotifier {
  final TickerProvider vsync;
  final StoryService _storyService = StoryService();
  final Function(int) onNextUser;
  final Function(int) onPreviousUser;
  final VoidCallback onComplete;

  late AnimationController progressController;
  late PageController pageController;

  UserWithStories? userWithStories;
  int? _prevUserId;
  int? _nextUserId;
  bool _isLoading = true;
  User? currentUser;

  List<StoryDetail> _stories = [];
  int _currentIndex = 0;
  bool _isPausedByGesture = false;
  bool _isPausedByUI = false;
  List<Color> gradientColors = [const Color(0xFF1A1A1A), Colors.black];

  final Map<int, StoryContentController> _contentControllers = {};
  final Map<int, TransformationController> _transformationControllers = {};

  bool get isLoading => _isLoading;
  List<StoryDetail> get stories => _stories;
  int get currentIndex => _currentIndex;
  Map<int, StoryContentController> get contentControllers => _contentControllers;
  Map<int, TransformationController> get transformationControllers => _transformationControllers;

  StoryViewController({
    required this.vsync,
    required this.onNextUser,
    required this.onPreviousUser,
    required this.onComplete,
  }) {
    progressController = AnimationController(vsync: vsync)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextContent();
        }
      });
  }

  Future<void> fetchStoriesForUser(int? userId, {int? initialStoryId}) async {
    // --- 👇 PERBAIKAN UTAMA ADA DI SINI 👇 ---
    // 1. Tambahkan pengecekan jika userId ternyata null
    if (userId == null) {
      log("Error: fetchStoriesForUser dipanggil dengan userId null.");
      _isLoading = false;
      // Mungkin tampilkan pesan error di sini jika perlu
      notifyListeners();
      return; // Hentikan eksekusi
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadCurrentUser();
      // 2. Sekarang kita bisa menggunakan 'userId' dengan aman karena sudah tidak null
      final feed = await _storyService.getPaginatedStoryFeedForUser(userId);
      userWithStories = feed.userWithStories;
      _prevUserId = feed.prevUserId;
      _nextUserId = feed.nextUserId;
      _stories = List.of(userWithStories!.stories);

      _contentControllers.forEach((_, controller) => controller.dispose());
      _contentControllers.clear();

      int startIndex = 0;
      if (initialStoryId != null) {
        final index = _stories.indexWhere((s) => s.storyId == initialStoryId);
        if (index != -1) startIndex = index;
      }

      pageController = PageController(initialPage: startIndex);

      if (_stories.isNotEmpty) {
        _startStoryAtIndex(startIndex);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      log("Error fetching stories for user: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startStoryAtIndex(int index) {
    if (index >= _stories.length) return;

    _currentIndex = index;
    _isLoading = false;
    notifyListeners();

    progressController.stop();
    progressController.reset();

    final story = _stories[index];
    _setGradientFromPalette(story);
    _updateProgressDuration(story);
    _storyService.viewStory(story.storyId);
  }

  void _nextContent() {
    transformationControllers[_currentIndex]?.value = Matrix4.identity();
    if (_currentIndex < _stories.length - 1) {
      final nextIndex = _currentIndex + 1;
      pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
      _startStoryAtIndex(nextIndex);
    } else if (_nextUserId != null) {
      onNextUser(_nextUserId!);
    } else {
      onComplete();
    }
  }

  void _previousContent() {
    transformationControllers[_currentIndex]?.value = Matrix4.identity();
    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      pageController.animateToPage(prevIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
      _startStoryAtIndex(prevIndex);
    } else if (_prevUserId != null) {
      onPreviousUser(_prevUserId!);
    } else {
      onComplete();
    }
  }

  void handleTap(BuildContext context, Offset tapPosition) {
    if (_isPausedByUI) return;
    final screenWidth = MediaQuery.of(context).size.width;
    if (tapPosition.dx < screenWidth * 0.3) {
      _previousContent();
    } else {
      _nextContent();
    }
  }

  void pause({bool byGesture = false, bool byUI = false}) {
    if (byGesture) _isPausedByGesture = true;
    if (byUI) _isPausedByUI = true;
    progressController.stop();
    _contentControllers[_currentIndex]?.pause();
    notifyListeners();
  }

  void resume({bool byGesture = false, bool byUI = false}) {
    if (byGesture) _isPausedByGesture = false;
    if (byUI) _isPausedByUI = false;
    if (!_isPausedByGesture && !_isPausedByUI) {
      final currentScale = _transformationControllers[_currentIndex]?.value.getMaxScaleOnAxis() ?? 1.0;
      if (currentScale <= 1.0) {
        progressController.forward();
        _contentControllers[_currentIndex]?.resume();
      }
    }
    notifyListeners();
  }

  void setVideoDuration(Duration duration) {
    if (progressController.duration != duration) {
      progressController.duration = duration;
    }
  }

  void _updateProgressDuration(StoryDetail story) {
    Duration duration;
    if (story.isMusicStory) {
      duration = Duration(milliseconds: story.musicClipDurationMs ?? 15000);
      progressController.duration = duration;
    } else if (!story.isVideo) {
      duration = const Duration(seconds: 5);
      progressController.duration = duration;
    }
  }

  Future<void> deleteCurrentStory(BuildContext context) async {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;
    final storyToDelete = _stories[_currentIndex];
    final bool success = await _storyService.deleteStory(storyToDelete.storyId);
    if (success) {
      _stories.removeAt(_currentIndex);
      if (_stories.isEmpty) {
        userWithStories = null;
      } else {
        final newIndex = _currentIndex.clamp(0, _stories.length - 1);
        pageController.jumpToPage(newIndex);
        _startStoryAtIndex(newIndex);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus cerita.')),
        );
      }
    }
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await SecureStorage.getUserId();
      if (userId == null) throw Exception("User ID tidak ditemukan");
      currentUser = User(id: userId, username: '...');
    } catch (e) {
      log("Gagal memuat current user: $e");
    }
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF" + hexColor;
    return Color(int.parse(hexColor, radix: 16));
  }

  void _setGradientFromPalette(StoryDetail story) {
    if (story.colorPalette != null && story.colorPalette!.isNotEmpty) {
      final colorsFromApi = story.colorPalette!.take(2).map((hex) => _colorFromHex(hex)).toList();
      gradientColors = colorsFromApi.length == 1 ? [colorsFromApi[0], Colors.black] : colorsFromApi;
    } else {
      gradientColors = [const Color(0xFF1A1A1A), Colors.black];
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (pageController.hasClients) {
      pageController.dispose();
    }
    progressController.dispose();
    _contentControllers.forEach((_, c) => c.dispose());
    _transformationControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
}