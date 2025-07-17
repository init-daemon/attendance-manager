import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:presence_manager/core/app/app_router.dart';
import 'package:presence_manager/services/db_service.dart';
import 'package:presence_manager/core/utils/logger.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  print('Database path: ' + await getDatabasesPath());

  // await DbService.initialize(fresh: true);

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PresenceManagerApp extends StatelessWidget {
  const PresenceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presence Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/members',
    );
  }
}
