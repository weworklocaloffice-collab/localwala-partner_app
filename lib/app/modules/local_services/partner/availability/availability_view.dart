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
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Staff, weekly hours and coverage for the provider.
/// Writes go straight to the server (upsert); staff list refreshes below.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _staffName = TextEditingController();
  final TextEditingController _locality = TextEditingController();

  String _message = '';
  List<Map<String, dynamic>> _staff = const <Map<String, dynamic>>[];

  @override
  void dispose() {
    _staffName.dispose();
    _locality.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final DioApiResponse response = await _repository.staff();
      final Map<String, dynamic> body = decodeBody(response);
      final List<dynamic> raw =
          (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      if (mounted) {
        setState(() {
          _staff = raw.whereType<Map<String, dynamic>>().toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _message = '${AppLocalizations.of(context)?.ls_staff_load_failed ?? 'Staff load failed'}: $e');
    }
  }

  Future<void> _run(Future<dynamic> Function() call, String ok) async {
    try {
      await call();
      if (mounted) setState(() => _message = ok);
    } catch (e) {
      if (mounted) setState(() => _message = AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e');
    }
  }

  Future<void> _addStaff() async {
    if (_staffName.text.trim().isEmpty) {
      setState(() => _message = AppLocalizations.of(context)?.ls_staff_name_required ?? 'Staff name required');
      return;
    }
    await _run(
      () => _repository.createStaff(
        <String, dynamic>{'name': _staffName.text.trim()}),
      AppLocalizations.of(context)?.ls_staff_added ?? 'Staff added',
    );
    _staffName.clear();
    await _loadStaff();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
         Text(AppLocalizations.of(context)?.ls_staff ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final Map<String, dynamic> s in _staff)
          Card(
            child: ListTile(
              title: Text('${s['name'] ?? ''}'),
              subtitle: Text(
                '${AppLocalizations.of(context)?.ls_skills_label ?? 'Skills'}: ${((s['skills'] ?? []) as List).join(', ')}\n'
                '${AppLocalizations.of(context)?.ls_shifts ?? 'Shifts'}: ${((s['shifts'] ?? []) as List).length} · ${AppLocalizations.of(context)?.ls_leave ?? 'Leave'}: ${((s['leave'] ?? []) as List).length} · ${s['status'] ?? ''}',
              ),
            ),
          ),
        TextField(
          controller: _staffName,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_staff_name ?? 'Staff name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addStaff,
           child: Text(AppLocalizations.of(context)?.ls_add_staff ?? 'Add staff'),
        ),
        const SizedBox(height: 16),
         Text(AppLocalizations.of(context)?.ls_coverage ?? 'Coverage', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _locality,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_locality_coverage ?? 'Locality (coverage)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _run(
            () => _repository.saveCoverage(
              <String, dynamic>{
                'localities': <String>[_locality.text.trim()],
              },
            ),
            AppLocalizations.of(context)?.ls_coverage_saved ?? 'Coverage saved',
          ),
           child: Text(AppLocalizations.of(context)?.ls_save_coverage ?? 'Save coverage'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _run(
            () => _repository.saveAvailability(
              <String, dynamic>{
                'day': DateTime.now().weekday % 7,
                'open': '09:00',
                'close': '20:00',
                'slotMinutes': 60,
              },
            ),
            AppLocalizations.of(context)?.ls_today_hours_saved ?? 'Today hours saved (09:00-20:00)',
          ),
           child: Text(AppLocalizations.of(context)?.ls_save_today_hours ?? 'Save today hours'),
        ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message),
          ),
      ],
    );
  }
}
