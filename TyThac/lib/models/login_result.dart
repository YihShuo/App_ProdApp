class LoginResult {
  final String result;
  final String status;
  final String userID;
  final String userName;
  final String group;

  const LoginResult({
    required this.result,
    required this.status,
    required this.userID,
    required this.userName,
    required this.group,
  });

  factory LoginResult.fromJson(json) {
    return LoginResult(
      result: json['result'],
      status: json['status'],
      userID: json['userID'],
      userName: json['userName'],
      group: json['group'],
    );
  }
}