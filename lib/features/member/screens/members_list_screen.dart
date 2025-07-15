import 'package:flutter/material.dart';
import 'package:presence_manager/features/member/widgets/members_table.dart';
import 'package:presence_manager/services/mock_data_service.dart';
import 'package:presence_manager/features/member/models/member.dart';
import 'package:presence_manager/features/member/screens/member_create_screen.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  late Future<List<Member>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = MockDataService.loadMembers();
  }

  void _refreshMembers() {
    setState(() {
      _membersFuture = MockDataService.loadMembers();
    });
  }

  void _navigateToCreateScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemberCreateScreen()),
    );
    _refreshMembers();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Membres',
      body: FutureBuilder<List<Member>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: MembersTable(
                    members: snapshot.data!,
                    onEdit: _refreshMembers,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _navigateToCreateScreen(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un membre'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToCreateScreen(context),
        ),
      ],
    );
  }
}
