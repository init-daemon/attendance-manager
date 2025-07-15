class Member {
  final String id;
  String firstName;
  String lastName;
  DateTime birthDate;
  bool isHidden;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.isHidden = false,
  });

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'isHidden': isHidden ? 1 : 0,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      birthDate: DateTime.parse(map['birthDate']),
      isHidden: map['isHidden'] == 1,
    );
  }
}
