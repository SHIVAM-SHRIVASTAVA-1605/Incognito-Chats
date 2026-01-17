import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/config.dart';
import '../models/message_model.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Event callbacks
  Function(MessageModel)? onNewMessage;
  Function(String)? onMessageDeleted;
  Function(String, Map<String, List<String>>)? onReactionAdded;
  Function(String, Map<String, List<String>>)? onReactionRemoved;
  Function(String)? onError;

  void connect(String token) {
    _socket = IO.io(
      Config.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('Socket connected');
      _isConnected = true;
      // Authenticate
      _socket!.emit('authenticate', token);
    });

    _socket!.on('authenticated', (data) {
      if (data['success'] == true) {
        print('Socket authenticated');
      } else {
        print('Socket authentication failed: ${data['error']}');
        disconnect();
      }
    });

    _socket!.on('disconnect', (_) {
      print('Socket disconnected');
      _isConnected = false;
    });

    _socket!.on('newMessage', (data) {
      print('New message received');
      if (onNewMessage != null) {
        final message = MessageModel.fromJson(data);
        onNewMessage!(message);
      }
    });

    _socket!.on('messageDeleted', (data) {
      print('Message deleted: ${data['messageId']}');
      if (onMessageDeleted != null) {
        onMessageDeleted!(data['messageId']);
      }
    });

    _socket!.on('reactionAdded', (data) {
      print('Reaction added to message: ${data['messageId']}');
      if (onReactionAdded != null) {
        final reactions = (data['reactions'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
        onReactionAdded!(data['messageId'], reactions);
      }
    });

    _socket!.on('reactionRemoved', (data) {
      print('Reaction removed from message: ${data['messageId']}');
      if (onReactionRemoved != null) {
        final reactions = (data['reactions'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
        onReactionRemoved!(data['messageId'], reactions);
      }
    });

    _socket!.on('error', (data) {
      print('Socket error: ${data['message']}');
      if (onError != null) {
        onError!(data['message']);
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void joinConversation(String conversationId) {
    if (_isConnected) {
      _socket!.emit('joinConversation', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    if (_isConnected) {
      _socket!.emit('leaveConversation', conversationId);
    }
  }

  void sendMessage(String conversationId, String content) {
    if (_isConnected) {
      _socket!.emit('sendMessage', {
        'conversationId': conversationId,
        'content': content,
      });
    }
  }

  void deleteMessage(String messageId, String conversationId) {
    if (_isConnected) {
      _socket!.emit('deleteMessage', {
        'messageId': messageId,
        'conversationId': conversationId,
      });
    }
  }

  void addReaction(String messageId, String emoji, String conversationId) {
    if (_isConnected) {
      _socket!.emit('addReaction', {
        'messageId': messageId,
        'emoji': emoji,
        'conversationId': conversationId,
      });
    }
  }

  void removeReaction(String messageId, String emoji, String conversationId) {
    if (_isConnected) {
      _socket!.emit('removeReaction', {
        'messageId': messageId,
        'emoji': emoji,
        'conversationId': conversationId,
      });
    }
  }
}
