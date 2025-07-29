import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GoogleDriveService {
  static const String _backupFolderName = 'AttendanceAppBackups';
  static drive.DriveApi? _driveApi;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<String?> backupFileToDrive(
    String filePath, {
    String? fileName,
  }) async {
    try {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          return 'Erreur: Pas de connexion internet';
        }
      } on SocketException catch (_) {
        return 'Erreur: Pas de connexion internet';
      }

      if (_driveApi == null) {
        await _initializeDriveApi();
        if (_driveApi == null) return null;
      }

      final String folderId = await _getOrCreateBackupFolder();
      final File file = File(filePath);

      if (!await file.exists()) {
        return 'Erreur: Fichier introuvable';
      }

      final String finalFileName =
          fileName ??
          'attendance_app_db_${DateFormat('dd-MM-yyyy_HH:mm').format(DateTime.now())}.db';

      final drive.File fileMetadata = drive.File()
        ..name = finalFileName
        ..parents = [folderId]
        ..description = 'Sauvegarde ${DateTime.now().toString()}';

      final drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      return uploadedFile.id;
    } catch (e) {
      debugPrint('Erreur Google Drive: $e');
      return null;
    }
  }

  static Future<String?> restoreFromDrive(BuildContext context) async {
    try {
      if (_driveApi == null) {
        await _initializeDriveApi();
        if (_driveApi == null) return null;
      }

      final String folderId = await _getOrCreateBackupFolder();
      final files = await _driveApi!.files.list(
        q: "'$folderId' in parents and mimeType != 'application/vnd.google-apps.folder' and trashed = false",
        orderBy: 'createdTime desc',
      );

      if (files.files == null || files.files!.isEmpty) {
        return 'Aucune sauvegarde disponible';
      }

      final recentFiles = files.files!.take(5).toList();

      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choisir une sauvegarde'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recentFiles.length,
                itemBuilder: (context, index) {
                  final file = recentFiles[index];
                  return ListTile(
                    title: Text(file.name ?? 'Sauvegarde ${index + 1}'),
                    onTap: () => Navigator.pop(context, file),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );

      if (selectedFile == null) return null;

      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, selectedFile.name!);
      final file = File(tempPath);
      final sink = file.openWrite();

      final media =
          await _driveApi!.files.get(
                selectedFile.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      await media.stream.pipe(sink);
      await sink.close();

      return tempPath;
    } catch (e) {
      debugPrint('Erreur restauration Google Drive: $e');
      return null;
    }
  }

  static Future<drive.File?> _selectFileToRestore(
    List<drive.File> files,
  ) async {
    if (files.isNotEmpty) {
      return files.first;
    }
    return null;
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

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Erreur lors de la récupération du user: $e');
      return null;
    }
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
