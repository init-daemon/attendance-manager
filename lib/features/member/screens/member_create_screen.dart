import 'package:flutter/material.dart';
import '../widgets/member_form.dart';
import '../models/member.dart';
import '../../../services/member_table_service.dart';

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
