class Individual {
  final String id;
  String firstName;
  String lastName;
  DateTime birthDate;
  bool isHidden;

  Individual({
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

  factory Individual.fromMap(Map<String, dynamic> map) {
    return Individual(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      birthDate: DateTime.parse(map['birthDate']),
      isHidden: map['isHidden'] == 1,
    );
  }
}
