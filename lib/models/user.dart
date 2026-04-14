class User {
  final int id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? fatherName;
  final String? cnic;
  final String? gender;
  final String? number;
  final String? city;
  final String? uni;
  final String? workplace;
  final String? feePaid;
  final String? registerFor;
  final String? usertype;

  User({
    required this.id,
    this.username,
    this.email,
    this.fullName,
    this.fatherName,
    this.cnic,
    this.gender,
    this.number,
    this.city,
    this.uni,
    this.workplace,
    this.feePaid,
    this.registerFor,
    this.usertype,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      fatherName: json['father_name'] as String?,
      cnic: json['cnic'] as String?,
      gender: json['gender'] as String?,
      number: json['number'] as String?,
      city: json['city'] as String?,
      uni: json['uni'] as String?,
      workplace: json['workplace'] as String?,
      feePaid: json['fee_paid'] as String?,
      registerFor: json['register_for'] as String?,
      usertype: json['usertype'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'full_name': fullName,
        'father_name': fatherName,
        'cnic': cnic,
        'gender': gender,
        'number': number,
        'city': city,
        'uni': uni,
        'workplace': workplace,
        'fee_paid': feePaid,
        'register_for': registerFor,
        'usertype': usertype,
      };

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (username != null && username!.isNotEmpty) {
      return username!.contains('@') ? username!.split('@').first : username!;
    }
    return 'Student';
  }
}
