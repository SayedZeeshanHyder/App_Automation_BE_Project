class UserModel {
  final String id;
  final String userName;
  final String email;
  final String role;
  final String deviceToken;
  final String organisationId;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    required this.deviceToken,
    required this.organisationId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      role: json['role'],
      deviceToken: json['deviceToken'],
      organisationId: json['organisationId'],
    );
  }
}