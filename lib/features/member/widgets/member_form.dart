import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/models/member.dart';

class MemberForm extends StatefulWidget {
  final Member? member;
  final Function(Member) onSave;
  final bool isCreate;

  const MemberForm({
    super.key,
    this.member,
    required this.onSave,
    this.isCreate = true,
  });

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;
  DateTime? _birthDate;
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
    _contactController = TextEditingController(
      text: widget.member?.contact ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.member?.description ?? '',
    );
    _birthDate = widget.member?.birthDate;
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
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Contact (optionnel)',
              hintText: 'Téléphone ou email',
            ),
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              hintText: 'Informations supplémentaires',
            ),
            maxLines: 3,
          ),
          ListTile(
            title: const Text('Date de naissance (optionnel)'),
            subtitle: Text(
              _birthDate != null
                  ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                  : 'Non spécifiée',
            ),
            trailing: _birthDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _birthDate = null;
                      });
                    },
                  )
                : null,
            onTap: () async {
              try {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Theme.of(context).primaryColor,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (selectedDate != null && mounted) {
                  setState(() {
                    _birthDate = selectedDate;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
          ),
          if (!widget.isCreate)
            SwitchListTile(
              title: const Text('Mise en corbeille'),
              value: _isHidden,
              onChanged: (value) {
                setState(() {
                  _isHidden = value;
                });
              },
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/members',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final member = Member(
                      id:
                          widget.member?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      contact: _contactController.text.isNotEmpty
                          ? _contactController.text
                          : null,
                      description: _descriptionController.text.isNotEmpty
                          ? _descriptionController.text
                          : null,
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
        ],
      ),
    );
  }
}
