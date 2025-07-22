import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class GoogleDriveService {
  static const String _backupFolderName = 'AttendanceAppBackups';
  static drive.DriveApi? _driveApi;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<String?> backupFileToDrive(String filePath) async {
    try {
      if (_driveApi == null) {
        await _initializeDriveApi();
        if (_driveApi == null) {
          debugPrint('Erreur: Impossible d\'initialiser Google Drive API');

          return null;
        }
      }

      final String folderId = await _getOrCreateBackupFolder();
      final File file = File(filePath);

      if (!await file.exists()) {
        debugPrint('Erreur: Le fichier à sauvegarder n\'existe pas');

        return null;
      }

      final String fileName =
          'attendance_app_${DateTime.now().millisecondsSinceEpoch}.db';
      final drive.File fileMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      debugPrint(
        'Sauvegarde réussie: ${uploadedFile.name} (ID: ${uploadedFile.id})',
      );

      return '${uploadedFile.name} (ID: ${uploadedFile.id})';
    } catch (e) {
      debugPrint('Erreur Google Drive: $e');

      return null;
    }
  }

  static Future<void> _initializeDriveApi() async {
    try {
      debugPrint('Début de l\'initialisation Google Sign-In');

      final account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('Annulation par l\'utilisateur');

        return;
      }

      debugPrint('Compte sélectionné: ${account.email}');

      final auth = await account.authentication;

      debugPrint('Authentification réussie');

      final httpClient = IOClient(
        HttpClient()
          ..connectionTimeout = const Duration(seconds: 10)
          ..badCertificateCallback = ((_, __, ___) => true),
      );

      _driveApi = drive.DriveApi(AuthClient(httpClient, auth.accessToken!));
      debugPrint('API Drive initialisée avec succès');
    } catch (e, stack) {
      debugPrint('ERREUR CRITIQUE: $e');
      debugPrint('STACKTRACE: $stack');
      _driveApi = null;
    }
  }

  static Future<String> _getOrCreateBackupFolder() async {
    final existingFolders = await _driveApi!.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName' and trashed=false",
      spaces: 'drive',
    );

    if (existingFolders.files!.isNotEmpty) {
      return existingFolders.files!.first.id!;
    }

    final newFolder = await _driveApi!.files.create(
      drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );

    return newFolder.id!;
  }
}

class AuthClient extends http.BaseClient {
  final http.Client _client;
  final String _token;

  AuthClient(this._client, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';

    return _client.send(request);
  }
}
