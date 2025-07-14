import 'package:flutter/material.dart';
import '../models/member.dart';

class MemberForm extends StatefulWidget {
  final Member? member;
  final Function(Member) onSave;

  const MemberForm({super.key, this.member, required this.onSave});

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late DateTime _birthDate;
  late bool _isHidden;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.member?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.member?.lastName ?? '',
    );
    _birthDate = widget.member?.birthDate ?? DateTime.now();
    _isHidden = widget.member?.isHidden ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'Prénom'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un prénom';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          ListTile(
            title: const Text('Date de naissance'),
            subtitle: Text(
              '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
            ),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() {
                  _birthDate = selectedDate;
                });
              }
            },
          ),
          SwitchListTile(
            title: const Text('Caché'),
            value: _isHidden,
            onChanged: (value) {
              setState(() {
                _isHidden = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final member = Member(
                  id:
                      widget.member?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  birthDate: _birthDate,
                  isHidden: _isHidden,
                );
                widget.onSave(member);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
