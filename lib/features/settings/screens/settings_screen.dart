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

  Future<void> _backupDatabase() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = null;
    });

    try {
      if (!await _checkStoragePermissions()) {
        setState(() {
          _isBackingUp = false;
          _backupStatus =
              "Permission d'accès au stockage refusée. Veuillez autoriser l'accès dans les paramètres de l'application.";
        });
        return;
      }

      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Choisissez le dossier de sauvegarde",
      );

      final dbPath = await DbService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        setState(() {
          _isBackingUp = false;
          _backupStatus = "Fichier de base de données introuvable.";
        });
        return;
      }

      String backupPath;
      if (directoryPath == null) {
        final downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          setState(() {
            _isBackingUp = false;
            _backupStatus =
                "Impossible d'accéder au dossier de téléchargement.";
          });
          return;
        }
        backupPath = '${downloadsDir.path}/attendance_backup.db';
      } else {
        backupPath = '$directoryPath/attendance_backup.db';
      }

      await dbFile.copy(backupPath);
      setState(() {
        _isBackingUp = false;
        _backupStatus = "Sauvegarde réussie à : $backupPath";
      });
    } catch (e) {
      setState(() {
        _isBackingUp = false;
        _backupStatus = "Erreur lors de la sauvegarde : $e";
      });
    }
  }

  Future<void> _backupToGoogleDrive() async {
    setState(() {
      _isBackingUpToGoogleDrive = true;
      _backupStatus = null;
    });

    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _isBackingUpToGoogleDrive = false;
        _backupStatus =
            "Connexion internet requise pour accéder à Google Drive";
      });
      return;
    }

    try {
      final dbPath = await DbService.getDatabasePath();
      final String? drivePath = await GoogleDriveService.backupFileToDrive(
        dbPath,
      );

      setState(() {
        _isBackingUpToGoogleDrive = false;
        _backupStatus = drivePath != null
            ? "Sauvegarde sur Google Drive réussie"
            : "Échec de la sauvegarde sur Google Drive";
      });
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

      if (backupPath == null) {
        setState(() {
          _isRestoringFromGoogleDrive = false;
          _backupStatus =
              "Aucun fichier sélectionné ou erreur lors de la restauration";
        });
        return;
      }

      final String autoBackupPath = await _autoBackupBeforeImport();
      if (autoBackupPath.isNotEmpty) {
        _backupStatus = "Sauvegarde automatique effectuée : $autoBackupPath";
      }

      final Database importedDb = await openDatabase(
        backupPath,
        readOnly: true,
      );
      final bool schemaValid = await _validateDatabaseSchema(importedDb);
      await importedDb.close();

      if (!schemaValid) {
        setState(() {
          _isRestoringFromGoogleDrive = false;
          _backupStatus =
              "Le schéma de la base de données importée est invalide.";
        });
        return;
      }

      final appDbPath = await DbService.getDatabasePath();
      try {
        await deleteDatabase(appDbPath);
      } catch (e) {
        developer.log('Erreur suppression ancienne base : $e');
      }
      await File(backupPath).copy(appDbPath);

      setState(() {
        _isRestoringFromGoogleDrive = false;
        _backupStatus = "Restauration depuis Google Drive réussie !";
      });
    } catch (e) {
      setState(() {
        _isRestoringFromGoogleDrive = false;
        _backupStatus =
            "Erreur lors de la restauration depuis Google Drive: $e";
      });
    }
  }

  Future<void> _importDatabase() async {
    setState(() {
      _isImporting = true;
      _backupStatus = null;
    });

    try {
      if (!await _checkStoragePermissions()) {
        setState(() {
          _isImporting = false;
          _backupStatus =
              "Permission d'accès au stockage refusée. Veuillez autoriser l'accès dans les paramètres de l'application.";
        });
        return;
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
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

      final String importPath = result.files.single.path!;
      final String backupPath = await _autoBackupBeforeImport();
      if (backupPath.isNotEmpty) {
        _backupStatus = "Sauvegarde automatique effectuée : $backupPath";
      }

      final Database importedDb = await openDatabase(
        importPath,
        readOnly: true,
      );
      final bool schemaValid = await _validateDatabaseSchema(importedDb);
      await importedDb.close();

      if (!schemaValid) {
        setState(() {
          _isImporting = false;
          _backupStatus =
              "Le schéma de la base de données importée est invalide.";
        });
        return;
      }

      final appDbPath = await DbService.getDatabasePath();
      try {
        await deleteDatabase(appDbPath);
      } catch (e) {
        developer.log('Erreur suppression ancienne base : $e');
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

  Future<bool> _checkStoragePermissions() async {
    if (Platform.isAndroid) {
      //vérifier et demander MANAGE_EXTERNAL_STORAGE pour Android 11+
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      //vérifier et demander les permissions standard pour les autres versions
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      //vérifier les permissions accordées
      final manageStatus = await Permission.manageExternalStorage.status;
      final storageStatus = await Permission.storage.status;

      return manageStatus.isGranted || storageStatus.isGranted;
    }
    return true;
  }

  Future<bool> _validateDatabaseSchema(Database db) async {
    return await MemberTableService.checkSchema(db) &&
        await EventTableService.checkSchema(db) &&
        await EventOrganizationTableService.checkSchema(db) &&
        await EventParticipantTableService.checkSchema(db);
  }

  Future<String> _autoBackupBeforeImport() async {
    try {
      final dbPath = await DbService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return "";

      final Directory backupDir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Documents/attendance_app_backup')
          : Directory(
              p.join(
                (await getApplicationDocumentsDirectory()).path,
                "attendance_app_backup",
              ),
            );

      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final existing = backupDir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                p.basename(f.path).startsWith("attendance_backup_") &&
                p.extension(f.path) == ".db",
          )
          .toList();

      int maxNum = existing.fold(0, (max, f) {
        final match = RegExp(
          r'attendance_backup_(\d+)\.db',
        ).firstMatch(p.basename(f.path));
        final num = int.tryParse(match?.group(1) ?? "0") ?? 0;
        return num > max ? num : max;
      });

      final backupPath = p.join(
        backupDir.path,
        "attendance_backup_${maxNum + 1}.db",
      );
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Paramètres',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "Sauvegarde locale",
              description:
                  "Créez une copie de votre base de données sur votre appareil.",
              children: [
                _buildActionButton(
                  icon: Icons.backup,
                  label: "Sauvegarder localement",
                  isLoading: _isBackingUp,
                  onPressed: _backupDatabase,
                ),
                _buildActionButton(
                  icon: Icons.file_upload,
                  label: "Importer une base de données",
                  isLoading: _isImporting,
                  onPressed: _importDatabase,
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            _buildSection(
              title: "Sauvegarde cloud",
              description:
                  "Sauvegardez et restaurez vos données depuis Google Drive.",
              children: [
                _buildActionButton(
                  icon: Icons.cloud_upload,
                  label: "Sauvegarder sur Google Drive",
                  isLoading: _isBackingUpToGoogleDrive,
                  onPressed: _backupToGoogleDrive,
                ),
                _buildActionButton(
                  icon: Icons.cloud_download,
                  label: "Restaurer depuis Google Drive",
                  isLoading: _isRestoringFromGoogleDrive,
                  onPressed: _restoreFromGoogleDrive,
                ),
              ],
            ),

            if (_backupStatus != null) ...[
              const SizedBox(height: 24),
              _buildStatusMessage(_backupStatus!),
            ],
            const SizedBox(height: 24),
            _buildInfoBox(
              "Conseil : Conservez plusieurs sauvegardes dans différents endroits (appareil local, cloud, support externe) pour maximiser la sécurité de vos données.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: isLoading ? const CircularProgressIndicator() : Text(label),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message) {
    final bool isSuccess =
        message.contains("réussie") ||
        message.contains("réussi") ||
        message.contains("Google Drive réussie");
    final bool isPermissionError = message.contains("Permission");

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isSuccess ? Colors.green[800] : Colors.red[800],
            ),
          ),
          if (isPermissionError) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openAppSettings,
              child: const Text('Ouvrir les paramètres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _openAppSettings() async {
    if (await Permission.manageExternalStorage.isPermanentlyDenied ||
        await Permission.storage.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}
