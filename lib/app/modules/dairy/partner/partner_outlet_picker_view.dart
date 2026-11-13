import 'package:flutter/material.dart';

class PartnerOutletPickerScreen extends StatelessWidget {
  const PartnerOutletPickerScreen({super.key, required this.outlets, required this.onSelect, this.loading = false});

  final List<Map<String, dynamic>> outlets;
  final ValueChanged<String> onSelect;
  final bool loading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose an outlet')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : outlets.isEmpty
            ? const Center(child: Text('No approved Dairy outlet is linked to this account.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  const Text('Select the outlet you want to manage. Access is checked by the server for every request.'),
                  const SizedBox(height: 12),
                  ...outlets.map((Map<String, dynamic> outlet) {
                    final String id = outlet['id']?.toString() ?? outlet['_id']?.toString() ?? '';
                    final String name = outlet['name']?.toString().trim().isNotEmpty == true
                        ? outlet['name'].toString()
                        : 'Dairy outlet';
                    final String model = outlet['businessModel']?.toString().replaceAll('_', ' ') ?? 'Agreement pending';
                    final String locality = outlet['locality'] is Map ? (outlet['locality']['name']?.toString() ?? '') : '';
                    final String city = outlet['city'] is Map ? (outlet['city']['name']?.toString() ?? '') : '';
                    final String location = <String>[locality, city].where((String value) => value.isNotEmpty).join(', ');
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                        title: Text(name),
                        subtitle: Text(<String>[model, location].where((String value) => value.isNotEmpty).join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: id.isEmpty ? null : () => onSelect(id),
                      ),
                    );
                  }),
                ],
              ),
  );
}
