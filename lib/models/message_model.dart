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
  String? replyToId;

  @HiveField(9)
  ReplyToMessage? replyToMessage;

  @HiveField(10)
  Map<String, List<String>> reactions;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    this.sender,
    this.status = 'pending',
    this.replyToId,
    this.replyToMessage,
    Map<String, List<String>>? reactions,
  }) : reactions = reactions ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory MessageModel.fromJson(Map<String, dynamic> json) {
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
      replyToId: json['replyToId'] as String?,
      replyToMessage: json['replyToMessage'] != null
          ? ReplyToMessage.fromJson(
              json['replyToMessage'] as Map<String, dynamic>)
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>).map((e) => e.toString()).toList(),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'sender': sender?.toJson(),
      'status': status,
      'reactions': reactions,
    };
  }
}

@HiveType(typeId: 3)
class ReplyToMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String senderId;

  @HiveField(2)
  String content;

  @HiveField(3)
  UserModel? sender;

  ReplyToMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.sender,
  });

  factory ReplyToMessage.fromJson(Map<String, dynamic> json) {
    return ReplyToMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'sender': sender?.toJson(),
    };
  }
}
