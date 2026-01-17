import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
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

  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      print('🔧 UserService.uploadProfilePicture() - Uploading file: ${imageFile.path}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/users/profile/picture'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer ${_authService.token}',
      });

      // Add file with explicit content type
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      print('🔧 UserService.uploadProfilePicture() - File extension: $fileExtension');
      
      String contentType = 'image/jpeg';
      if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'webp') {
        contentType = 'image/webp';
      }
      print('🔧 UserService.uploadProfilePicture() - Content type: $contentType');
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          imageFile.path,
          contentType: http_parser.MediaType.parse(contentType),
        ),
      );

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      final data = jsonDecode(response.body);
      print('🔧 UserService.uploadProfilePicture() - Response: $data');

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        print('🔧 UserService.uploadProfilePicture() - User from response: ${user.displayName}, profilePicture: ${user.profilePicture}');
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/users/profile/picture'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Delete failed'};
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

  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/users/block'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({'userId': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Block failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/users/unblock'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({'userId': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Unblock failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/blocked'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final users = (data['blockedUsers'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
        return {'success': true, 'users': users};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get blocked users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> isUserBlocked(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/blocked/$userId'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'isBlocked': data['isBlocked']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to check block status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
