class UserModel {
  final int userId;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final bool isActive;

  const UserModel({
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.isActive,
  })
  ;

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        userId: j['user_id'] as int,
        role: j['role'] as String,
        firstName: j['first_name'] as String,
        lastName: j['last_name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_active': isActive,
      };
}
