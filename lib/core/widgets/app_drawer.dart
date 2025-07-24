import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:attendance_app/features/member/widgets/profile_avatar.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
    });
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await _googleSignIn.signInSilently();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // utilisateur n'est pas connecté ou une erreur est survenue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentUser != null) ...[
                  _currentUser!.photoUrl != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            _currentUser!.photoUrl!,
                          ),
                        )
                      : ProfileAvatar(
                          initials:
                              _currentUser!.displayName?.isNotEmpty == true
                              ? _currentUser!.displayName![0]
                              : '?',
                          radius: 30,
                        ),
                  const SizedBox(height: 10),
                  Text(
                    _currentUser!.displayName ?? 'Nom inconnu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentUser!.email,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Non connecté',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ],
            ),
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
            leading: const Icon(Icons.list),
            title: const Text('Liste des événements'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Evénements'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/event-organizations');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Compte Google'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/google-account');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
}
