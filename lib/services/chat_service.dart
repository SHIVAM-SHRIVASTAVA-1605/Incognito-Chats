import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'auth_service.dart';

class ChatService {
  final AuthService _authService;

  ChatService(this._authService);

  Future<Map<String, dynamic>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/chat/conversations'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final conversations = (data['conversations'] as List)
            .map((c) => ConversationModel.fromJson(c))
            .toList();
        return {'success': true, 'conversations': conversations};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to load conversations'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/chat/conversations'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({'otherUserId': otherUserId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final conversation = ConversationModel.fromJson(data['conversation']);
        return {'success': true, 'conversation': conversation};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create conversation'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMessages(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/chat/conversations/$conversationId/messages'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final messages = (data['messages'] as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        return {'success': true, 'messages': messages};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to load messages'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/chat/conversations/$conversationId'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Failed to delete conversation'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/chat/messages/$messageId'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Failed to delete message'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
