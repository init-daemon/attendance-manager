import 'package:flutter/material.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showDrawer;
  final List<Widget>? appBarActions;

  const AppLayout({
    super.key,
    required this.body,
    required this.title,
    this.showDrawer = true,
    this.appBarActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, elevation: 4),
      drawer: showDrawer ? const AppDrawer() : null,
      body: SafeArea(child: body),
    );
  }
}
