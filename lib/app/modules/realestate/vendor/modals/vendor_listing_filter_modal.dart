import 'package:flutter/material.dart';

/// Reusable filter bottom sheet for vendor listings.
///
/// Returns the selected filter map via Navigator.pop, or null if dismissed.
class VendorListingFilterModal extends StatefulWidget {
  const VendorListingFilterModal({super.key, this.initial});

  final Map<String, dynamic>? initial;

  static Future<Map<String, dynamic>?> show(BuildContext context, {Map<String, dynamic>? initial}) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => VendorListingFilterModal(initial: initial),
    );
  }

  @override
  State<VendorListingFilterModal> createState() => _VendorListingFilterModalState();
}

class _VendorListingFilterModalState extends State<VendorListingFilterModal> {
  String? _status;
  String? _category;

  static const List<String> _statuses = <String>['ALL', 'DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'SOLD'];
  static const List<String> _categories = <String>['ALL', 'APARTMENT', 'VILLA', 'PLOT', 'COMMERCIAL'];

  @override
  void initState() {
    super.initState();
    _status = widget.initial?['status']?.toString() ?? 'ALL';
    _category = widget.initial?['category']?.toString() ?? 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Filter listings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            items: _statuses.map((String s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
            onChanged: (String? v) => setState(() => _status = v),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories.map((String c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
            onChanged: (String? v) => setState(() => _category = v),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(<String, dynamic>{
              'status': _status,
              'category': _category,
            }),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
