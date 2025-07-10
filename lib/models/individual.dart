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
}
