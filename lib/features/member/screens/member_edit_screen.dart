import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/screens/member_view_screen.dart';
import 'package:attendance_app/features/member/widgets/member_form.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/services/member_table_service.dart';

class MemberEditScreen extends StatelessWidget {
  final Member member;
  static const String routeName = '/members/edit';

  const MemberEditScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier un membre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, MemberViewScreen(member: member));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MemberForm(
          member: member,
          onSave: (updated) async {
            await MemberTableService.update(updated);
            Navigator.pop(context, updated);
          },
        ),
      ),
    );
  }
}
