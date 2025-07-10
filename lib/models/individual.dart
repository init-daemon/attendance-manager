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
}
