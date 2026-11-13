/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
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

/// Staff and bookable-resource management for partners.
/// Resources are capacity units (rooms, vehicles, equipment) whose
/// allocations are checked for overlap by the API.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  static const List<String> _dayLabels = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  bool _loading = true;
  String? _error;
  List<dynamic> _staff = <dynamic>[];
  List<dynamic> _resources = <dynamic>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DioApiResponse> responses = await Future.wait(
        <Future<DioApiResponse>>[_repository.staff(), _repository.resources()],
      );
      final Map<String, dynamic> staffBody = decodeBody(responses[0]);
      final Map<String, dynamic> resourceBody = decodeBody(responses[1]);
      setState(() {
        _staff = staffBody['results'] ?? staffBody['data'] ?? <dynamic>[];
        _resources =
            resourceBody['results'] ?? resourceBody['data'] ?? <dynamic>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  /// Staff need weekly shifts, otherwise the API refuses to allocate them to
  /// a booking ("Staff is not available for this time").
  Future<void> _createStaff() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController skills = TextEditingController();
    final List<TextEditingController> shiftStarts = <TextEditingController>[];
    final List<TextEditingController> shiftEnds = <TextEditingController>[];
    for (int i = 0; i < 7; i++) {
      shiftStarts.add(TextEditingController());
      shiftEnds.add(TextEditingController());
    }
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
         title: Text(AppLocalizations.of(context)?.ls_add_staff ?? 'Add staff'),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)?.ls_name ?? 'Name'),
                ),
                TextField(
                  controller: skills,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.ls_skills ?? 'Skills (comma separated)',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.ls_working_hours_hint ?? 'Working hours (HH:MM 24h). Leave blank for a day off.',
                  style: const TextStyle(fontSize: 12),
                ),
                for (int day = 0; day < 7; day++)
                  Row(
                    children: <Widget>[
                      SizedBox(width: 42, child: Text(_dayLabels[day])),
                      Expanded(
                        child: TextField(
                          controller: shiftStarts[day],
                          decoration: const InputDecoration(
                            hintText: '09:00',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: shiftEnds[day],
                          decoration: const InputDecoration(
                            hintText: '18:00',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)?.ls_cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)?.ls_save ?? 'Save'),
          ),
        ],
      ),
    );
    final List<Map<String, dynamic>> shifts = <Map<String, dynamic>>[];
    for (int day = 0; day < 7; day++) {
      final String start = shiftStarts[day].text.trim();
      final String end = shiftEnds[day].text.trim();
      if (start.isEmpty || end.isEmpty) continue;
      shifts.add(<String, dynamic>{'day': day, 'start': start, 'end': end});
    }
    if (save == true && mounted) {
      try {
        await _repository.createStaff(<String, dynamic>{
          'name': name.text.trim(),
          'skills': skills.text
              .split(',')
              .map((String s) => s.trim())
              .where((String s) => s.isNotEmpty)
              .toList(),
          if (shifts.isNotEmpty) 'shifts': shifts,
        });
        await _load();
      } catch (e) {
        _showError(e);
      }
    }
    name.dispose();
    skills.dispose();
    for (final TextEditingController c in shiftStarts) {
      c.dispose();
    }
    for (final TextEditingController c in shiftEnds) {
      c.dispose();
    }
  }

  Future<void> _createResource() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController capacity = TextEditingController(text: '1');
    final TextEditingController turnaround = TextEditingController(text: '0');
    String kind = 'room';
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
               title: Text(AppLocalizations.of(context)?.ls_add_resource ?? 'Add resource'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)?.ls_name ?? 'Name'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)?.ls_kind ?? 'Kind'),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'room',
                         child: Text(AppLocalizations.of(context)?.ls_room ?? 'Room'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'vehicle',
                         child: Text(AppLocalizations.of(context)?.ls_vehicle ?? 'Vehicle'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'equipment',
                         child: Text(AppLocalizations.of(context)?.ls_equipment ?? 'Equipment'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'other',
                         child: Text(AppLocalizations.of(context)?.ls_other ?? 'Other'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() => kind = value);
                      }
                    },
                  ),
                  TextField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)?.ls_capacity ?? 'Capacity'),
                  ),
                  TextField(
                    controller: turnaround,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_turnaround_minutes ?? 'Turnaround minutes',
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)?.ls_cancel ?? 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)?.ls_save ?? 'Save'),
                ),
              ],
            ),
      ),
    );
    if (save == true && mounted) {
      try {
        await _repository.createResource(<String, dynamic>{
          'name': name.text.trim(),
          'kind': kind,
          'capacity': int.tryParse(capacity.text) ?? 1,
          'turnaroundMinutes': int.tryParse(turnaround.text) ?? 0,
        });
        await _load();
      } catch (e) {
        _showError(e);
      }
    }
    name.dispose();
    capacity.dispose();
    turnaround.dispose();
  }

  Future<void> _toggleStaff(Map<String, dynamic> row) async {
    try {
      await _repository.updateStaff(
        '${row['_id'] ?? row['id']}',
        <String, dynamic>{
          'status': row['status'] == 'active' ? 'inactive' : 'active',
        },
      );
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggleResource(Map<String, dynamic> row) async {
    try {
      await _repository.updateResource(
        '${row['_id'] ?? row['id']}',
        <String, dynamic>{
          'status': row['status'] == 'active' ? 'inactive' : 'active',
        },
      );
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$error') ?? 'Failed: $error')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!),
            TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry')),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
           title: Text(AppLocalizations.of(context)?.ls_team_resources ?? 'Team & resources'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Staff'),
              Tab(text: 'Resources'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              onPressed: _createStaff,
              icon: const Icon(Icons.person_add),
                  tooltip: AppLocalizations.of(context)?.ls_add_staff ?? 'Add staff',
            ),
            IconButton(
              onPressed: _createResource,
              icon: const Icon(Icons.add_box),
                  tooltip: AppLocalizations.of(context)?.ls_add_resource ?? 'Add resource',
            ),
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            _staff.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)?.ls_no_staff ?? 'No staff found'))
                : ListView.builder(
                    itemCount: _staff.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> row =
                          Map<String, dynamic>.from(_staff[index] as Map);
                      return ListTile(
                        title: Text('${row['name'] ?? 'Staff'}'),
                        subtitle: Text(
                          'Skills: ${row['skills'] ?? <dynamic>[]}',
                        ),
                        trailing: Switch(
                          value: row['status'] == 'active',
                          onChanged: (_) => _toggleStaff(row),
                        ),
                      );
                    },
                  ),
            _resources.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)?.ls_no_resources ?? 'No resources found'))
                : ListView.builder(
                    itemCount: _resources.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> row =
                          Map<String, dynamic>.from(_resources[index] as Map);
                      return ListTile(
                        title: Text('${row['name'] ?? 'Resource'}'),
                        subtitle: Text(
                          '${row['kind'] ?? 'other'} · capacity ${row['capacity'] ?? 1}',
                        ),
                        trailing: Switch(
                          value: row['status'] == 'active',
                          onChanged: (_) => _toggleResource(row),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
