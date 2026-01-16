import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late final UserService _userService;
  late final ChatService _chatService;
  final SocketService _socketService = SocketService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  String? _error;

  AuthService get authService => _authService;
  UserService get userService => _userService;
  ChatService get chatService => _chatService;
  SocketService get socketService => _socketService;
  StorageService get storageService => _storageService;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.isAuthenticated;
  UserModel? get currentUser => _authService.currentUser;

  AppProvider() {
    _userService = UserService(_authService);
    _chatService = ChatService(_authService);
  }

  Future<void> initialize() async {
    await _storageService.initialize();
    await _authService.initialize();
    
    if (_authService.isAuthenticated && _authService.token != null) {
      _socketService.connect(_authService.token!);
      // Clean up expired messages on startup
      await _storageService.cleanupExpiredMessages();
    }
    
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> register(String email, String password) async {
    setLoading(true);
    clearError();
    
    final result = await _authService.register(email, password);
    
    if (result['success']) {
      if (_authService.token != null) {
        _socketService.connect(_authService.token!);
      }
      setLoading(false);
      notifyListeners();
      return true;
    } else {
      setError(result['error']);
      setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearError();
    
    final result = await _authService.login(email, password);
    
    if (result['success']) {
      if (_authService.token != null) {
        _socketService.connect(_authService.token!);
      }
      setLoading(false);
      notifyListeners();
      return true;
    } else {
      setError(result['error']);
      setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _socketService.disconnect();
    await _authService.logout();
    await _storageService.clearAllData();
    notifyListeners();
  }
}
