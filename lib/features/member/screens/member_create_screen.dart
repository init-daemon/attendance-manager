import 'package:flutter/material.dart';
import 'package:presence_manager/features/member/widgets/member_form.dart';
import 'package:presence_manager/features/member/models/member.dart';
import 'package:presence_manager/services/member_table_service.dart';

class MemberCreateScreen extends StatefulWidget {
  const MemberCreateScreen({super.key});

  @override
  State<MemberCreateScreen> createState() => _MemberCreateScreenState();
}

class _MemberCreateScreenState extends State<MemberCreateScreen> {
  void _saveMember(Member member) async {
    await MemberTableService.insert(member);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un nouveau membre')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MemberForm(onSave: _saveMember),
      ),
    );
  }
}
