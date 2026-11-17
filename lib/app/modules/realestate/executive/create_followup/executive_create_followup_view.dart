import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';

class ExecutiveCreateFollowUpScreen extends StatefulWidget {
  const ExecutiveCreateFollowUpScreen({super.key, required this.leadId});

  final String leadId;

  @override
  State<ExecutiveCreateFollowUpScreen> createState() => _ExecutiveCreateFollowUpScreenState();
}

class _ExecutiveCreateFollowUpScreenState extends State<ExecutiveCreateFollowUpScreen> {
  final TextEditingController _notes = TextEditingController();
  String _mode = 'MAYBE_FOLLOW_UP';
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  static const List<String> _modes = <String>['MAYBE_FOLLOW_UP', 'CALL_BACK', 'SITE_VISIT', 'DOCUMENTS', 'OTHER'];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await RealEstateExecutiveRepository().createFollowUp(
        widget.leadId,
        nextFollowUpAt: _when,
        mode: _mode,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create follow-up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _mode,
              items: _modes.map((String m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
              onChanged: (String? v) => setState(() => _mode = v ?? _mode),
              decoration: const InputDecoration(labelText: 'Mode'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('When: ${_when.toLocal().toString().split('.').first}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final DateTime? d = await showDatePicker(
                  context: context,
                  initialDate: _when,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) {
                  final TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
                  setState(() => _when = DateTime(d.year, d.month, d.day, t?.hour ?? _when.hour, t?.minute ?? _when.minute));
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
