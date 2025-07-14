import 'package:flutter/material.dart';
import '../models/member.dart';
import '../screens/member_view_screen.dart';

class MembersTable extends StatelessWidget {
  final List<Member> members;
  final VoidCallback? onEdit;

  const MembersTable({super.key, required this.members, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Prénom')),
            DataColumn(label: Text('Date de naissance')),
            DataColumn(label: Text('Actions')),
          ],
          rows: members.map((member) {
            return DataRow(
              cells: [
                DataCell(Text(member.lastName)),
                DataCell(Text(member.firstName)),
                DataCell(Text(member.birthDate.toString())),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemberViewScreen(member: member),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/members/edit',
                            arguments: member,
                          );
                          if (result != null && result is Member) {
                            if (onEdit != null) onEdit!();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.hide_image),
                        onPressed: () {
                          // TODO: Gérer le hide
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
