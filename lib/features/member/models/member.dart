import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Member {
  final String id;
  String firstName;
  String lastName;
  DateTime? birthDate;
  bool isHidden;
  DateTime? hiddenAt;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.isHidden = false,
    this.hiddenAt,
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
      'birthDate': birthDate?.toIso8601String(),
      'isHidden': isHidden ? 1 : 0,
      'hiddenAt': hiddenAt?.toIso8601String(),
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    DateTime? birthDate;
    DateTime? hiddenAt;

    if (map['birthDate'] != null) {
      if (map['birthDate'] is String) {
        birthDate = DateTime.tryParse(map['birthDate']);
        birthDate ??= _parseDateString(map['birthDate']);
      } else if (map['birthDate'] is DateTime) {
        birthDate = map['birthDate'];
      }
    }

    if (map['hiddenAt'] != null) {
      if (map['hiddenAt'] is String) {
        hiddenAt = DateTime.tryParse(map['hiddenAt']);
      } else if (map['hiddenAt'] is DateTime) {
        hiddenAt = map['hiddenAt'];
      }
    }

    return Member(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      birthDate: birthDate,
      isHidden: map['isHidden'] == 1,
      hiddenAt: hiddenAt,
    );
  }

  static DateTime? _parseDateString(String dateStr) {
    final cleaned = dateStr.trim().replaceAll('\\', '/').replaceAll('-', '/');

    final possibleFormats = [
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'MM/dd/yyyy',
    ];

    for (final format in possibleFormats) {
      try {
        final date = DateFormat(format).parse(cleaned);

        return date;
      } catch (e) {
        debugPrint('Failed to parse with $format: $e');
      }
    }

    try {
      final date = DateTime.parse(cleaned);
      debugPrint('Successfully parsed with DateTime.parse: $date');
      return date;
    } catch (e) {
      debugPrint('Failed to parse with DateTime.parse: $e');
    }

    return null;
  }
}
