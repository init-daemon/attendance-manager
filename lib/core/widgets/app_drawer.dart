import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Menu Principal'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Membres'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/members');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Événements'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Evénements organisés'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/event-organizations');
            },
          ),
        ],
      ),
    );
  }
}
