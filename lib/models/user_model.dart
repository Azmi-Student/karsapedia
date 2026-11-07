import 'school_model.dart';

class UserModel {
  final int id;
  final String name;
  final String? username;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? avatar;
  final String status;
  final SchoolModel? school;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.avatar,
    required this.status,
    this.school,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'siswa',
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
      status: json['status'] ?? 'active',
      school: json['school'] != null && json['school'] is Map<String, dynamic>
          ? SchoolModel.fromJson(json['school'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'role': role,
    'phone_number': phoneNumber,
    'avatar': avatar,
    'status': status,
    'school': school?.toJson(),
  };
}

