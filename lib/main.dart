// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:presence_manager/core/app/app_router.dart';
import 'package:presence_manager/services/individual_db_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final individuals = await IndividualDbService.getAllIndividuals();

  if (individuals.isEmpty) {
    await IndividualDbService.seedDatabase(count: 10);
  }

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
      initialRoute: '/individuals',
    );
  }
}
