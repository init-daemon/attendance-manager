import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/features/member/screens/member_view_screen.dart';
import 'package:attendance_app/services/date_service.dart';
import 'package:attendance_app/services/member_table_service.dart';

class MembersTable extends StatelessWidget {
  final List<Member> members;
  final Future<void> Function()? onEdit;

  const MembersTable({super.key, required this.members, this.onEdit});

  Future<void> _toggleHide(BuildContext context, Member member) async {
    final updatedMember = Member(
      id: member.id,
      firstName: member.firstName,
      lastName: member.lastName,
      birthDate: member.birthDate,
      isHidden: !member.isHidden,
      hiddenAt: !member.isHidden ? DateTime.now() : null,
    );
    await MemberTableService.update(updatedMember);
    if (onEdit != null) {
      await onEdit!();
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    Member member,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            member.isHidden ? 'Restaurer le membre' : 'Supprimer le membre',
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  member.isHidden
                      ? 'Voulez-vous vraiment restaurer ce membre ?'
                      : 'Voulez-vous vraiment supprimer ce membre ?',
                ),
                if (member.isHidden && member.hiddenAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Supprimé le: ${DateService.formatFr(member.hiddenAt!, withHour: true)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                member.isHidden ? 'Restaurer' : 'Supprimer',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _toggleHide(context, member);
              },
            ),
          ],
        );
      },
    );
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
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Status')),
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
                          member.isHidden
                              ? Icons.restore_from_trash
                              : Icons.delete,
                          color: iconColor,
                        ),
                        tooltip: member.isHidden
                            ? 'Restaurer le membre'
                            : 'Supprimer le membre',
                        onPressed: () async {
                          await _showDeleteConfirmationDialog(context, member);
                        },
                      ),
                    ],
                  ),
                ),
                DataCell(Text(member.lastName)),
                DataCell(Text(member.firstName)),
                DataCell(Text(member.contact ?? '-')),
                DataCell(Text(member.description ?? '-')),
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
                      member.isHidden ? 'Supprimé' : 'Actif',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    member.birthDate != null
                        ? DateService.formatFr(
                            member.birthDate!,
                            withHour: false,
                          )
                        : 'Non spécifiée',
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
