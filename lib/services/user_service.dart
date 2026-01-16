import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService;

  UserService(this._authService);

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? bio,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/users/profile'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          if (displayName != null) 'displayName': displayName,
          if (bio != null) 'bio': bio,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/search?query=$query'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final users = (data['users'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
        return {'success': true, 'users': users};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Search failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
