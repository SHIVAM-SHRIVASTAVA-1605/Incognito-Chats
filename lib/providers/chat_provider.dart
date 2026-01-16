import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final AuthService _authService;
  final ChatService _chatService;
  final SocketService _socketService;
  final StorageService _storageService;

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider({
    required AuthService authService,
    required ChatService chatService,
    required SocketService socketService,
    required StorageService storageService,
  })  : _authService = authService,
        _chatService = chatService,
        _socketService = socketService,
        _storageService = storageService {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onNewMessage = (message) {
      // Add message to list if it's for current conversation
      if (message.conversationId == _currentConversationId) {
        _messages.add(message);
        notifyListeners();
      }
      
      // Save to storage
      _storageService.saveMessage(message);
      
      // Update conversation's last message time
      _updateConversationLastMessage(message.conversationId, message.content);
    };

    _socketService.onMessageDeleted = (messageId) {
      _messages.removeWhere((m) => m.id == messageId);
      _storageService.deleteMessage(messageId);
      notifyListeners();
    };
  }

  void _updateConversationLastMessage(String conversationId, String content) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index].lastMessageAt = DateTime.now();
      _conversations[index].lastMessagePreview = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      notifyListeners();
      _storageService.saveConversation(_conversations[index]);
    }
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load from local storage first
    _conversations = _storageService.getConversations();
    notifyListeners();

    // Then fetch from server
    final result = await _chatService.getConversations();
    
    if (result['success']) {
      _conversations = result['conversations'];
      await _storageService.saveConversations(_conversations);
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ConversationModel?> getOrCreateConversation(String otherUserId) async {
    final result = await _chatService.getOrCreateConversation(otherUserId);
    
    if (result['success']) {
      final conversation = result['conversation'] as ConversationModel;
      await _storageService.saveConversation(conversation);
      
      // Add to list if not already there
      if (!_conversations.any((c) => c.id == conversation.id)) {
        _conversations.insert(0, conversation);
        notifyListeners();
      }
      
      return conversation;
    } else {
      _error = result['error'];
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _currentConversationId = conversationId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load from local storage first
    _messages = _storageService.getMessages(conversationId);
    notifyListeners();

    // Join conversation room
    _socketService.joinConversation(conversationId);

    // Fetch from server
    final result = await _chatService.getMessages(conversationId);
    
    if (result['success']) {
      _messages = result['messages'];
      await _storageService.saveMessages(_messages);
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  void sendMessage(String content) {
    if (_currentConversationId != null && content.trim().isNotEmpty) {
      _socketService.sendMessage(_currentConversationId!, content.trim());
    }
  }

  void deleteMessage(String messageId) {
    if (_currentConversationId != null) {
      _socketService.deleteMessage(messageId, _currentConversationId!);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final result = await _chatService.deleteConversation(conversationId);
    
    if (result['success']) {
      _conversations.removeWhere((c) => c.id == conversationId);
      await _storageService.deleteConversation(conversationId);
      notifyListeners();
    } else {
      _error = result['error'];
      notifyListeners();
    }
  }

  void leaveConversation() {
    if (_currentConversationId != null) {
      _socketService.leaveConversation(_currentConversationId!);
      _currentConversationId = null;
      _messages = [];
    }
  }

  @override
  void dispose() {
    leaveConversation();
    super.dispose();
  }
}
