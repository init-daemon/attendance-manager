import 'dart:io';
import 'package:path/path.dart' as p;

class Logger {
  static Future<File> _getLogFile() async {
    final directory = Directory(p.join(Directory.current.path, '.local_logs'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final path = p.join(directory.path, 'app.log');

    return File(path);
  }

  static Future<void> log(String message) async {
    final file = await _getLogFile();
    final now = DateTime.now().toIso8601String();
    await file.writeAsString(
      '[$now] $message\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}
