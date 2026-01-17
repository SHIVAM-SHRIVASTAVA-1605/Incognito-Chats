import 'package:hive/hive.dart';
import 'user_model.dart';

part 'conversation_model.g.dart';

@HiveType(typeId: 1)
class ConversationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  UserModel otherUser;

  @HiveField(2)
  DateTime lastMessageAt;

  @HiveField(3)
  String? lastMessagePreview;

  @HiveField(4)
  bool isBlocked;

  ConversationModel({
    required this.id,
    required this.otherUser,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.isBlocked = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      otherUser: UserModel.fromJson(json['otherUser'] as Map<String, dynamic>),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String).toLocal(),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUser': otherUser.toJson(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
      'isBlocked': isBlocked,
    };
  }
}
