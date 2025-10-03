import 'package:flutter/foundation.dart';

import '../../../core/exceptions/app_exception.dart';
import '../../inspections/data/models.dart';
import '../data/auth_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final AuthRepository _repository;

  PortalProfile? _profile;
  bool _isLoading = false;
  AppException? _error;

  PortalProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  AppException? get error => _error;
  bool get isAuthenticated => _profile != null;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.login(username: username, password: password);
    } on AppException catch (exception) {
      _error = exception;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _profile = null;
    notifyListeners();
  }
}
