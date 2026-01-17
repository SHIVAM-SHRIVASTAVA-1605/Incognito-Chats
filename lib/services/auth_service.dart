import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/user_model.dart';

class AuthService {
  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    final userJson = prefs.getString('current_user');
    print('🔧 AuthService.initialize() - userJson: $userJson');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
      print('🔧 AuthService.initialize() - Loaded user: ${_currentUser?.displayName}, profilePicture: ${_currentUser?.profilePicture}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<void> updateCurrentUser(UserModel user) async {
    print('🔧 AuthService.updateCurrentUser() - Updating user: ${user.displayName}, profilePicture: ${user.profilePicture}');
    _currentUser = user;
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    print('🔧 AuthService.updateCurrentUser() - Saving to prefs: $userJson');
    await prefs.setString('current_user', userJson);
    
    // Verify it was saved
    final savedJson = prefs.getString('current_user');
    print('🔧 AuthService.updateCurrentUser() - Verified saved: $savedJson');
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
}
