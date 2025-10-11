// lib/providers/upload_provider.dart
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/story_service.dart'; // <-- Import StoryService

enum UploadType { post, story }

class UploadTask {
  final String id;
  final UploadType type; // <-- Tambahkan tipe unggahan
  final File? mediaFile; // <-- Buat nullable untuk story musik
  final Map<String, String> fields;
  final Uint8List thumbnail;
  final StreamController<double> _progressController = StreamController.broadcast();
  bool isCancelled = false;

  UploadTask({
    required this.id,
    required this.type,
    this.mediaFile,
    required this.fields,
    required this.thumbnail,
  });

  Stream<double> get progress => _progressController.stream;

  void updateProgress(double value) {
    if (!_progressController.isClosed) {
      _progressController.add(value);
    }
  }

  void dispose() {
    _progressController.close();
  }
}

class UploadProvider with ChangeNotifier {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService(); // <-- Tambahkan StoryService
  UploadTask? _currentTask;
  StreamSubscription? _progressSubscription;

  UploadTask? get currentTask => _currentTask;
  bool get isUploading => _currentTask != null;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  Future<void> startUpload({
    required UploadType type,
    required Map<String, String> fields,
    File? mediaFile, // <-- Buat nullable
    required Uint8List thumbnail,
  }) async {
    if (_currentTask != null) return;

    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentTask = UploadTask(
        id: taskId,
        type: type,
        mediaFile: mediaFile,
        fields: fields,
        thumbnail: thumbnail
    );
    _uploadProgress = 0.0;

    _progressSubscription = _currentTask!.progress.listen((progress) {
      _uploadProgress = progress;
      notifyListeners();
    });

    notifyListeners();

    try {
      // --- Logika untuk memilih service yang tepat ---
      if (type == UploadType.post) {
        await _postService.createPost(
            _currentTask!.fields,
            mediaFile: _currentTask!.mediaFile!, // Post pasti punya file
            onProgress: (sent, total) {
              if (_currentTask?.isCancelled == false) {
                _currentTask!.updateProgress(sent / total);
              }
            }
        );
      } else if (type == UploadType.story) {
        await _storyService.createStory(
            _currentTask!.fields,
            mediaFile: _currentTask!.mediaFile, // Story bisa saja tidak punya file (mode musik)
            onProgress: (sent, total) {
              if (_currentTask?.isCancelled == false) {
                _currentTask!.updateProgress(sent / total);
              }
            }
        );
      }
      _finishUpload();
    } catch (e) {
      print("Upload failed or was cancelled: $e");
      _finishUpload();
    }
  }

  void cancelUpload() {
    if (_currentTask != null) {
      _currentTask!.isCancelled = true;
      _finishUpload();
    }
  }

  void _finishUpload() {
    _progressSubscription?.cancel();
    _currentTask?.dispose();
    _currentTask = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }
}