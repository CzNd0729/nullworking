class User {
  final int? userId;
  final String? userName;
  final String? realName;
  final String? phone;
  final String? email;
  final int? deptId;
  final String? deptName;

  User({
    this.userId,
    this.userName,
    this.realName,
    this.phone,
    this.email,
    this.deptId,
    this.deptName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int?,
      userName: json['userName']?.toString(),
      realName: json['realName']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      deptId: json['deptId'] as int?,
      deptName: json['deptName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'realName': realName,
      'phone': phone,
      'email': email,
      'deptId': deptId,
      'deptName': deptName,
    };
  }
}
