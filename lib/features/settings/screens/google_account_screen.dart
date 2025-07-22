import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/member/widgets/profile_avatar.dart';

class GoogleAccountScreen extends StatefulWidget {
  const GoogleAccountScreen({super.key});

  @override
  State<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends State<GoogleAccountScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = await _googleSignIn.signInSilently();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _handleSignIn() async {
    try {
      final user = await _googleSignIn.signIn();
      setState(() {
        _currentUser = user;
      });
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $error')));
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
      setState(() {
        _currentUser = null;
      });
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Compte Google',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentUser != null) ...[
                _currentUser!.photoUrl != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_currentUser!.photoUrl!),
                      )
                    : ProfileAvatar(
                        initials: _currentUser!.displayName?.isNotEmpty == true
                            ? _currentUser!.displayName![0]
                            : '?',
                        radius: 50,
                      ),
                const SizedBox(height: 20),
                Text(
                  _currentUser!.displayName ?? 'Nom inconnu',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(_currentUser!.email, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleSignOut,
                  child: const Text('Se déconnecter'),
                ),
              ] else ...[
                const Text(
                  'Non connecté à Google',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter avec Google'),
                  onPressed: _handleSignIn,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
