import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  ProfileModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profileService = ProfileService();
      _currentUser = await profileService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
