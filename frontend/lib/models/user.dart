class User {
  final int? userId;
  final String? userName;
  final String? realName;
  final String? phoneNumber;
  final String? email;
  final int? deptId;
  final String? deptName;
  final int? roleId;
  final String? roleName;

  User({
    this.userId,
    this.userName,
    this.realName,
    this.phoneNumber,
    this.email,
    this.deptId,
    this.deptName,
    this.roleId,
    this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int?,
      userName: json['userName']?.toString(),
      realName: json['realName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      deptId: json['deptId'] as int?,
      deptName: json['deptName']?.toString(),
      roleId: json['roleId'] as int?,
      roleName: json['roleName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'realName': realName,
      'phoneNumber': phoneNumber,
      'email': email,
      'deptId': deptId,
      'deptName': deptName,
      'roleId': roleId,
      'roleName': roleName,
    };
  }
}
