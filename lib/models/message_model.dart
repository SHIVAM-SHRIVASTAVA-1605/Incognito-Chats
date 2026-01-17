import 'package:hive/hive.dart';
import 'user_model.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime expiresAt;

  @HiveField(6)
  UserModel? sender;

  @HiveField(7)
  String status; // 'pending', 'sent', 'delivered'

  @HiveField(8)
  Map<String, List<String>> reactions; // emoji -> list of user IDs

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    this.sender,
    this.status = 'pending',
    Map<String, List<String>>? reactions,
  }) : reactions = reactions ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Parse reactions
    Map<String, List<String>> reactionsMap = {};
    if (json['reactions'] != null) {
      final reactionsJson = json['reactions'] as Map<String, dynamic>;
      reactionsJson.forEach((emoji, users) {
        reactionsMap[emoji] = List<String>.from(users as List);
      });
    }

    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'sent',
      reactions: reactionsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'sender': sender?.toJson(),
      'status': status,
      'reactions': reactions,
    };
  }
}
