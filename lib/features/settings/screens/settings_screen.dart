import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/services/db_service.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackingUp = false;
  String? _backupStatus;

  Future<void> _backupDatabase() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = null;
    });

    await Permission.storage.request();

    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Choisissez le dossier de sauvegarde",
      );

      if (directoryPath == null) {
        setState(() {
          _isBackingUp = false;
          _backupStatus = "Sauvegarde annulée.";
        });
        return;
      }

      final dbPath = await DbService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        setState(() {
          _isBackingUp = false;
          _backupStatus = "Fichier de base de données introuvable.";
        });
        return;
      }

      final backupFile = File('$directoryPath/attendance_backup.db');
      await dbFile.copy(backupFile.path);

      setState(() {
        _isBackingUp = false;
        _backupStatus = "Sauvegarde réussie à : ${backupFile.path}";
      });
    } catch (e) {
      setState(() {
        _isBackingUp = false;
        _backupStatus = "Erreur lors de la sauvegarde : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Paramètres',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sauvegarder les données",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Vous pouvez sauvegarder la base de données de l'application à l'emplacement de votre choix. "
              "Cela vous permet de conserver une copie de vos données en cas de besoin.",
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: _isBackingUp
                  ? const Text("Sauvegarde en cours...")
                  : const Text("Sauvegarder maintenant"),
              onPressed: _isBackingUp ? null : _backupDatabase,
            ),
            if (_backupStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                _backupStatus!,
                style: TextStyle(
                  color: _backupStatus!.contains("réussie")
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Conseil : Conservez la sauvegarde dans un endroit sûr (clé USB, cloud, etc.) pour éviter toute perte de données.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
