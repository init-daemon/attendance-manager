// lib/core/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:presence_manager/features/individual/screens/individuals_list_screen.dart';
import '../../features/individual/screens/individual_create_screen.dart';
import '../../features/individual/screens/individual_view_screen.dart';
import '../../features/individual/screens/individual_edit_screen.dart';
import '../../features/individual/models/individual.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const IndividualsListScreen());
      case '/individuals':
        return MaterialPageRoute(builder: (_) => const IndividualsListScreen());
      case '/individuals/create':
        return MaterialPageRoute(
          builder: (_) => const IndividualCreateScreen(),
        );
      case '/individuals/view':
        final individual = settings.arguments as Individual;
        return MaterialPageRoute(
          builder: (_) => IndividualViewScreen(individual: individual),
        );
      case '/individuals/edit':
        final individual = settings.arguments as Individual;
        return MaterialPageRoute(
          builder: (_) => IndividualEditScreen(individual: individual),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route non trouvée: ${settings.name}')),
          ),
        );
    }
  }
}
