import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/services/db_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/services/member_table_service.dart';
import 'package:attendance_app/services/event_table_service.dart';
import 'package:attendance_app/services/event_organization_table_service.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'dart:developer' as developer;
import 'package:attendance_app/services/google_drive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackingUp = false;
  String? _backupStatus;
  bool _isImporting = false;
  bool _isBackingUpToGoogleDrive = false;
  bool _isRestoringFromGoogleDrive = false;

  Future<void> _backupToGoogleDrive() async {
    setState(() {
      _isBackingUpToGoogleDrive = true;
      _backupStatus = null;
    });

    try {
      final dbPath = await DbService.getDatabasePath();
      final String? drivePath = await GoogleDriveService.backupFileToDrive(
        dbPath,
      );

      if (drivePath != null) {
        setState(() {
          _isBackingUpToGoogleDrive = false;
          _backupStatus = "Sauvegarde sur Google Drive réussie: $drivePath";
        });
      } else {
        setState(() {
          _isBackingUpToGoogleDrive = false;
          _backupStatus = "Échec de la sauvegarde sur Google Drive";
        });
      }
    } catch (e) {
      setState(() {
        _isBackingUpToGoogleDrive = false;
        _backupStatus = "Erreur lors de la sauvegarde sur Google Drive: $e";
      });
    }
  }

  Future<void> _restoreFromGoogleDrive() async {
    setState(() {
      _isRestoringFromGoogleDrive = true;
      _backupStatus = null;
    });

    try {
      final String? backupPath = await GoogleDriveService.restoreFromDrive(
        context,
      );

      if (backupPath != null) {
        String autoBackupPath = await _autoBackupBeforeImport();
        if (autoBackupPath.isNotEmpty) {
          _backupStatus = "Sauvegarde automatique effectuée : $autoBackupPath";
        }

        Database importedDb = await openDatabase(backupPath, readOnly: true);
        bool membersOk = await MemberTableService.checkSchema(importedDb);
        bool eventsOk = await EventTableService.checkSchema(importedDb);
        bool orgsOk = await EventOrganizationTableService.checkSchema(
          importedDb,
        );
        bool participantsOk = await EventParticipantTableService.checkSchema(
          importedDb,
        );
        await importedDb.close();

        if (!membersOk || !eventsOk || !orgsOk || !participantsOk) {
          setState(() {
            _isRestoringFromGoogleDrive = false;
            _backupStatus =
                "Erreur : le schéma de la base de données importée ne correspond pas à celui attendu.";
          });
          return;
        }

        final appDbPath = await DbService.getDatabasePath();
        try {
          await deleteDatabase(appDbPath);
        } catch (e) {
          developer.log(
            'Erreur lors de la suppression de l\'ancienne base : $e',
          );
        }
        await File(backupPath).copy(appDbPath);

        setState(() {
          _isRestoringFromGoogleDrive = false;
          _backupStatus = "Restauration depuis Google Drive réussie !";
        });
      } else {
        setState(() {
          _isRestoringFromGoogleDrive = false;
          _backupStatus =
              "Aucun fichier sélectionné ou erreur lors de la restauration";
        });
      }
    } catch (e) {
      setState(() {
        _isRestoringFromGoogleDrive = false;
        _backupStatus =
            "Erreur lors de la restauration depuis Google Drive: $e";
      });
    }
  }

  Future<void> _backupDatabase() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = null;
    });

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      setState(() {
        _isBackingUp = false;
        _backupStatus = "Permission d'accès au stockage refusée.";
      });
      return;
    }

    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Choisissez le dossier de sauvegarde",
      );

      if (directoryPath == null) {
        final downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir != null) {
          final dbPath = await DbService.getDatabasePath();
          final dbFile = File(dbPath);
          final backupFile = File('${downloadsDir.path}/attendance_backup.db');
          await dbFile.copy(backupFile.path);
          setState(() {
            _isBackingUp = false;
            _backupStatus =
                "Aucun dossier choisi. Sauvegarde effectuée dans : ${backupFile.path}";
          });
        } else {
          setState(() {
            _isBackingUp = false;
            _backupStatus =
                "Sauvegarde annulée. Impossible de choisir un dossier et accès au dossier de téléchargement refusé.";
          });
        }
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

  Future<String> _autoBackupBeforeImport() async {
    try {
      final dbPath = await DbService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return "";
      }

      Directory backupDir;
      if (Platform.isAndroid) {
        backupDir = Directory(
          '/storage/emulated/0/Documents/attendance_app_backup',
        );
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        backupDir = Directory(p.join(docsDir.path, "attendance_app_backup"));
      }

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final existing = backupDir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                p.basename(f.path).startsWith("attendance_backup_") &&
                p.extension(f.path) == ".db",
          )
          .toList();
      int maxNum = 0;
      for (final f in existing) {
        final match = RegExp(
          r'attendance_backup_(\d+)\.db',
        ).firstMatch(p.basename(f.path));
        if (match != null) {
          final num = int.tryParse(match.group(1) ?? "0");
          if (num != null && num > maxNum) maxNum = num;
        }
      }
      final nextNum = maxNum + 1;
      final backupPath = p.join(
        backupDir.path,
        "attendance_backup_$nextNum.db",
      );
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      return "";
    }
  }

  Future<void> _importDatabase() async {
    setState(() {
      _isImporting = true;
      _backupStatus = null;
    });

    //demande la permission d'accès au stockage (Android 11+ nécessite manageExternalStorage)
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      // Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.manageExternalStorage.isPermanentlyDenied) {
        await Permission.manageExternalStorage.request();
      }
      status = await Permission.manageExternalStorage.status;
    }

    if (!status.isGranted) {
      setState(() {
        _isImporting = false;
        _backupStatus =
            "Permission d'accès au stockage refusée. Veuillez autoriser l'accès dans les paramètres de l'application.";
      });
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Sélectionnez la base de données à importer",
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isImporting = false;
          _backupStatus = "Import annulé.";
        });
        return;
      }

      String importPath = result.files.single.path!;

      String backupPath = await _autoBackupBeforeImport();
      if (backupPath.isNotEmpty) {
        setState(() {
          _backupStatus = "Sauvegarde automatique effectuée : $backupPath";
        });
      }

      Database importedDb = await openDatabase(importPath, readOnly: true);

      bool membersOk = await MemberTableService.checkSchema(importedDb);
      bool eventsOk = await EventTableService.checkSchema(importedDb);
      bool orgsOk = await EventOrganizationTableService.checkSchema(importedDb);
      bool participantsOk = await EventParticipantTableService.checkSchema(
        importedDb,
      );

      await importedDb.close();

      if (!membersOk || !eventsOk || !orgsOk || !participantsOk) {
        setState(() {
          _isImporting = false;
          _backupStatus =
              "Erreur : le schéma de la base de données importée ne correspond pas à celui attendu.";
        });
        return;
      }

      final appDbPath = await DbService.getDatabasePath();
      final appDbFile = File(appDbPath);

      try {
        await deleteDatabase(appDbPath);
      } catch (e) {
        developer.log('Erreur lors de la suppression de l\'ancienne base : $e');
      }

      await File(importPath).copy(appDbPath);

      setState(() {
        _isImporting = false;
        _backupStatus =
            "Importation réussie ! La base de données a été remplacée.";
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _backupStatus = "Erreur lors de l'import : $e";
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
                  : const Text("Sauvegarder localement"),
              onPressed: _isBackingUp ? null : _backupDatabase,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: _isBackingUpToGoogleDrive
                  ? const Text("Sauvegarde sur Google Drive en cours...")
                  : const Text("Sauvegarder sur Google Drive"),
              onPressed: _isBackingUpToGoogleDrive
                  ? null
                  : _backupToGoogleDrive,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_download),
              label: _isRestoringFromGoogleDrive
                  ? const Text("Restauration depuis Google Drive en cours...")
                  : const Text("Restaurer depuis Google Drive"),
              onPressed: _isRestoringFromGoogleDrive
                  ? null
                  : _restoreFromGoogleDrive,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: _isImporting
                  ? const Text("Importation en cours...")
                  : const Text("Importer une base de données"),
              onPressed: _isImporting ? null : _importDatabase,
            ),
            if (_backupStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                _backupStatus!,
                style: TextStyle(
                  color:
                      _backupStatus!.contains("réussie") ||
                          _backupStatus!.contains("Importation réussie") ||
                          _backupStatus!.contains("Google Drive réussie")
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
