import 'package:flutter/material.dart';
import '../models/member.dart';
import '../widgets/profile_avatar.dart';
import '../../../core/widgets/app_layout.dart';
import '../../member/screens/member_edit_screen.dart';

class MemberViewScreen extends StatelessWidget {
  final Member member;
  static const String routeName = '/members/view';

  const MemberViewScreen({super.key, required this.member});

  String get initials =>
      '${member.firstName.isNotEmpty ? member.firstName[0] : ''}'
      '${member.lastName.isNotEmpty ? member.lastName[0] : ''}';

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails du membre',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditScreen(context),
        ),
      ],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              ProfileAvatar(initials: initials, radius: 50),
              const SizedBox(height: 20),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nom', member.lastName),
                      _buildInfoRow('Prénom', member.firstName),
                      _buildInfoRow(
                        'Date de naissance',
                        '${member.birthDate.day}/${member.birthDate.month}/${member.birthDate.year}',
                      ),
                      _buildInfoRow(
                        'Statut',
                        member.isHidden ? 'Caché' : 'Visible',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.pushNamed(
      context,
      MemberEditScreen.routeName,
      arguments: member,
    ).then((updatedMember) {
      if (updatedMember != null && updatedMember is Member) {
        Navigator.pop(context, updatedMember);
      }
    });
  }

  static void navigate(BuildContext context, Member member) {
    Navigator.pushNamed(context, routeName, arguments: member);
  }
}
