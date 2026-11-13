/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({super.key});

  @override
  State<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _radius = TextEditingController(text: '10');

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<String> _localities = <String>[];
  List<String> _pincodes = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _city.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse response = await _repository.coverage();
      final Map<String, dynamic> body = decodeBody(response);
      final Map<String, dynamic> coverage =
          (body['coverage'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      setState(() {
        _city.text = '${coverage['city'] ?? ''}';
        _radius.text = '${coverage['radiusKm'] ?? 10}';
        _localities = List<String>.from(
          (coverage['localities'] as List?) ?? <dynamic>[],
        ).where((String value) => value.isNotEmpty).toList();
        _pincodes = List<String>.from(
          (coverage['pincodes'] as List?) ?? <dynamic>[],
        ).where((String value) => value.isNotEmpty).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addValue({required bool pincode}) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            pincode
                ? (l10n?.ls_add_pincode ?? 'Add pincode')
                : (l10n?.ls_add_locality ?? 'Add locality'),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                pincode ? TextInputType.number : TextInputType.text,
            inputFormatters: pincode
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ]
                : null,
            decoration: InputDecoration(
              labelText: l10n?.ls_enter_value ?? 'Enter a value',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (String text) =>
                Navigator.of(dialogContext).pop(text.trim()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.ls_cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n?.ls_add ?? 'Add'),
            ),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      if (pincode) {
        if (!_pincodes.contains(value)) _pincodes.add(value);
      } else {
        if (!_localities.contains(value)) _localities.add(value);
      }
    });
  }

  Future<void> _save() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await _repository.saveCoverage(<String, dynamic>{
        'city': _city.text.trim(),
        'radiusKm': double.tryParse(_radius.text.trim()) ?? 10,
        'localities': _localities,
        'pincodes': _pincodes,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.ls_areas_saved ?? 'Service areas saved')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.ls_save_failed(e) ?? 'Could not save: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _valuesCard({
    required String title,
    required List<String> values,
    required String emptyLabel,
    required VoidCallback onAdd,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (values.isEmpty)
              Text(emptyLabel)
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final String value in values)
                    Chip(
                      label: Text(value),
                      onDeleted: () => setState(() => values.remove(value)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)?.ls_add ?? 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_areas_title ?? 'Service areas'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n?.ls_retry ?? 'Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  children: <Widget>[
                    if (_saving) const LinearProgressIndicator(),
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: <Widget>[
                            TextField(
                              controller: _city,
                              decoration: InputDecoration(
                                labelText: l10n?.ls_city ?? 'City',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _radius,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n?.ls_radius_km ?? 'Radius (km)',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _valuesCard(
                      title: l10n?.ls_localities ?? 'Localities',
                      values: _localities,
                      emptyLabel: l10n?.ls_no_localities ??
                          'No localities added yet',
                      onAdd: () => _addValue(pincode: false),
                    ),
                    _valuesCard(
                      title: l10n?.ls_pincodes ?? 'Pincodes',
                      values: _pincodes,
                      emptyLabel:
                          l10n?.ls_no_pincodes ?? 'No pincodes added yet',
                      onAdd: () => _addValue(pincode: true),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(l10n?.ls_save_coverage ?? 'Save coverage'),
                    ),
                  ],
                ),
    );
  }
}
