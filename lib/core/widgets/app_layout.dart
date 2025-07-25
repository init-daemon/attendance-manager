import 'package:flutter/material.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showDrawer;
  final List<Widget>? appBarActions;

  const AppLayout({
    Key? key,
    required this.body,
    required this.title,
    this.showDrawer = true,
    this.appBarActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildAppIcon(),
                    ),
                  ),
                ),
                if (appBarActions != null) ...appBarActions!,
              ],
            ),
          ],
        ),
      ),
      drawer: showDrawer ? const AppDrawer() : null,
      body: SafeArea(child: body),
    );
  }

  Widget _buildAppIcon() {
    try {
      return Image.asset(
        'assets/app_icon.png',
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.apps, size: 16, color: Colors.white);
        },
      );
    } catch (e) {
      return const Icon(Icons.apps, size: 16, color: Colors.white);
    }
  }
}
