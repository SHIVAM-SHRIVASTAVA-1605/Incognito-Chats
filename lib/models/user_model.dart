import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String? bio;

  @HiveField(3)
  String? profilePicture;

  @HiveField(4)
  List<String>? blockedUsers;

  UserModel({
    required this.id,
    required this.displayName,
    this.bio,
    this.profilePicture,
    this.blockedUsers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      profilePicture: json['profilePicture'] as String?,
      blockedUsers: json['blockedUsers'] != null 
        ? List<String>.from(json['blockedUsers'] as List)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'bio': bio,
      'profilePicture': profilePicture,
      'blockedUsers': blockedUsers,
    };
  }
}
