class Person {
  String uid;
  String fullName;
  String nickname;
  String email;
  String photoUrl;
  DateTime lastLogin;
  int dailyTransactionsMade;

  Person({
    required this.uid,
    required this.fullName,
    required this.nickname,
    required this.email,
    required this.photoUrl,
    required this.lastLogin,
    required this.dailyTransactionsMade,
  });
}
