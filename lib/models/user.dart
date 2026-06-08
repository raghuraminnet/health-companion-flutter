class User {
  final String id;
  final String name;
  final String email;
  final String gender;
  final int yearOfBirth;
  final String? mobile;
  final bool passwordResetRequired;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.yearOfBirth,
    this.mobile,
    this.passwordResetRequired = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      yearOfBirth: json['year_of_birth'],
      mobile: json['mobile'],
      passwordResetRequired: json['password_reset_required'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'year_of_birth': yearOfBirth,
      'mobile': mobile,
      'password_reset_required': passwordResetRequired,
      'created_at': createdAt.toIso8601String(),
    };
  }
}