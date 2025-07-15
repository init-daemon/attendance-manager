class DateService {
  static String formatFr(DateTime dateTime, {bool withHour = true}) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    String formatted = '$day/$month/$year';
    if (withHour) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      formatted += ' $hour:$minute';
    }
    return formatted;
  }

  static String formatFrLong(DateTime dateTime, {bool withHour = true}) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year.toString();
    String formatted = '$day $month $year';
    if (withHour) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      formatted += ' à $hour:$minute';
    }
    return formatted;
  }
}
