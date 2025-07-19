import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/features/member/screens/member_view_screen.dart';
import 'package:attendance_app/services/date_service.dart';
import 'package:attendance_app/services/member_table_service.dart';

class MembersTable extends StatelessWidget {
  final List<Member> members;
  final VoidCallback? onEdit;

  const MembersTable({super.key, required this.members, this.onEdit});

  Future<void> _toggleHide(BuildContext context, Member member) async {
    final updatedMember = Member(
      id: member.id,
      firstName: member.firstName,
      lastName: member.lastName,
      birthDate: member.birthDate,
      isHidden: !member.isHidden,
    );
    await MemberTableService.update(updatedMember);
    if (onEdit != null) onEdit!();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Actions')),
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Prénom')),
            DataColumn(label: Text('Caché')),
            DataColumn(label: Text('Date de naissance')),
          ],
          rows: members.map((member) {
            final colorScheme = Theme.of(context).colorScheme;
            final badgeColor = member.isHidden
                ? colorScheme.errorContainer
                : colorScheme.secondaryContainer;
            final iconColor = member.isHidden
                ? colorScheme.error
                : colorScheme.secondary;
            return DataRow(
              cells: [
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
                        icon: Icon(
                          member.isHidden ? Icons.person_off : Icons.person,
                          color: iconColor,
                        ),
                        tooltip: member.isHidden
                            ? 'Afficher le membre'
                            : 'Cacher le membre',
                        onPressed: () async {
                          await _toggleHide(context, member);
                        },
                      ),
                    ],
                  ),
                ),
                DataCell(Text(member.lastName)),
                DataCell(Text(member.firstName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.isHidden ? 'Oui' : 'Non',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(DateService.formatFr(member.birthDate, withHour: false)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
