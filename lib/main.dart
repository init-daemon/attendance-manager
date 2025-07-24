import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance_app/core/app/app_router.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/core/utils/logger.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Demander les permissions de stockage au démarrage
  await _requestStoragePermissions();

  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  print('Database path: ' + await getDatabasesPath());

  await DbService.initialize(fresh: true);

  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    final errorMessage = kReleaseMode
        ? "Une erreur s'est produite."
        : details.exceptionAsString();
    await Logger.log(details.exceptionAsString());
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/error',
      (route) => false,
      arguments: errorMessage,
    );
  };

  runApp(const PresenceManagerApp());
}

Future<void> _requestStoragePermissions() async {
  if (Platform.isAndroid) {
    //pour Android 13+ (API 33+)
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }

    //pour Android 10-12 (API 29-32)
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    //pour Android <10 (API <29)
    if (await Permission.accessMediaLocation.isDenied) {
      await Permission.accessMediaLocation.request();
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PresenceManagerApp extends StatelessWidget {
  const PresenceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      title: 'Attendance App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
