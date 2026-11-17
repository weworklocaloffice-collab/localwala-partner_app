import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _DayHours {
  _DayHours({
    required this.day,
    required this.label,
  });

  final int day;
  final String label;
  late bool enabled;
  late TimeOfDay open;
  late TimeOfDay close;
  late int slotMinutes;
  late int bufferMinutes;
  late int capacity;
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _staffName = TextEditingController();
  final TextEditingController _locality = TextEditingController();

  String _message = '';
  List<Map<String, dynamic>> _staff = const <Map<String, dynamic>>[];

  final List<_DayHours> _week = <_DayHours>[
    _DayHours(day: 1, label: 'Monday'),
    _DayHours(day: 2, label: 'Tuesday'),
    _DayHours(day: 3, label: 'Wednesday'),
    _DayHours(day: 4, label: 'Thursday'),
    _DayHours(day: 5, label: 'Friday'),
    _DayHours(day: 6, label: 'Saturday'),
    _DayHours(day: 0, label: 'Sunday'),
  ];

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
    _loadAvailability();
    _loadCoverage();
  }

  Future<void> _loadAvailability() async {
    try {
      final DioApiResponse response = await _repository.availability();
      final Map<String, dynamic> body = decodeBody(response);
      final List<dynamic> raw =
          (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        for (final dynamic entry in raw) {
          if (entry is! Map<String, dynamic>) continue;
          final int day = (entry['day'] as num?)?.toInt() ?? -1;
          _DayHours? target;
          for (final _DayHours d in _week) {
            if (d.day == day) {
              target = d;
              break;
            }
          }
          if (target == null) continue;
          target.enabled = '${entry['status'] ?? 'active'}' == 'active';
          target.open = _parseTime('${entry['open'] ?? ''}') ?? target.open;
          target.close = _parseTime('${entry['close'] ?? ''}') ?? target.close;
          target.slotMinutes = (entry['slotMinutes'] as num?)?.toInt() ?? target.slotMinutes;
          target.bufferMinutes = (entry['bufferMinutes'] as num?)?.toInt() ?? target.bufferMinutes;
          target.capacity = (entry['capacity'] as num?)?.toInt() ?? target.capacity;
        }
      });
    } catch (_) {
      // silent — grid falls back to defaults
    }
  }

  Future<void> _loadCoverage() async {
    try {
      final DioApiResponse response = await _repository.coverage();
      final Map<String, dynamic> body = decodeBody(response);
      final dynamic coverage = body['coverage'] ?? body['data'];
      if (coverage is Map<String, dynamic> && mounted) {
        final List<dynamic> localities = (coverage['localities'] ?? <dynamic>[]) as List<dynamic>;
        if (localities.isNotEmpty) {
          _locality.text = '${localities.first}';
        }
      }
    } catch (_) {
      // silent — no coverage saved yet
    }
  }

  TimeOfDay? _parseTime(String value) {
    final List<String> parts = value.split(':');
    if (parts.length < 2) return null;
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
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

  Future<void> _saveWeek() async {
    int saved = 0;
    for (final _DayHours d in _week) {
      if (!d.enabled) continue;
      await _repository.saveAvailability(<String, dynamic>{
        'day': d.day,
        'open': '${d.open.hour.toString().padLeft(2, '0')}:${d.open.minute.toString().padLeft(2, '0')}',
        'close': '${d.close.hour.toString().padLeft(2, '0')}:${d.close.minute.toString().padLeft(2, '0')}',
        'slotMinutes': d.slotMinutes,
        'bufferMinutes': d.bufferMinutes,
        'capacity': d.capacity,
        'status': 'active',
      });
      saved += 1;
    }
    if (mounted) {
      setState(() => _message = saved == 0 ? 'No days selected' : 'Saved $saved day(s)');
    }
  }

  Future<void> _pickTime(_DayHours d, bool isOpen) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? d.open : d.close,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        d.open = picked;
      } else {
        d.close = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        LsSectionHeader(title: l10n?.ls_staff ?? 'Staff'),
        if (_staff.isEmpty)
          const LsEmptyState(
            icon: Icons.people_outline,
            title: 'No staff yet',
            subtitle: 'Add staff below.',
          )
        else
          ..._staff.map((Map<String, dynamic> s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('${s['name'] ?? ''}'),
                  subtitle: Text(
                    '${l10n?.ls_skills_label ?? 'Skills'}: ${((s['skills'] ?? []) as List).join(', ')}\n'
                    '${l10n?.ls_shifts ?? 'Shifts'}: ${((s['shifts'] ?? []) as List).length} · ${l10n?.ls_leave ?? 'Leave'}: ${((s['leave'] ?? []) as List).length} · ${s['status'] ?? ''}',
                  ),
                ),
              )),
        TextField(
          controller: _staffName,
          decoration: InputDecoration(
            labelText: l10n?.ls_staff_name ?? 'Staff name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addStaff,
          child: Text(l10n?.ls_add_staff ?? 'Add staff'),
        ),
        const SizedBox(height: 24),
        LsSectionHeader(title: 'Weekly hours'),
        ..._week.map((_DayHours d) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(d.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: d.enabled,
                          onChanged: (bool v) => setState(() => d.enabled = v),
                        ),
                      ],
                    ),
                    if (d.enabled) ...<Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickTime(d, true),
                              child: Text('Open ${d.open.format(context)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickTime(d, false),
                              child: Text('Close ${d.close.format(context)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              initialValue: '${d.slotMinutes}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Slot min',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (String v) => d.slotMinutes = int.tryParse(v) ?? d.slotMinutes,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: '${d.bufferMinutes}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Buffer min',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (String v) => d.bufferMinutes = int.tryParse(v) ?? d.bufferMinutes,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: '${d.capacity}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Capacity',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (String v) => d.capacity = int.tryParse(v) ?? d.capacity,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _saveWeek,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save weekly hours'),
        ),
        const SizedBox(height: 24),
        LsSectionHeader(title: l10n?.ls_coverage ?? 'Coverage'),
        TextField(
          controller: _locality,
          decoration: InputDecoration(
            labelText: l10n?.ls_locality_coverage ?? 'Locality (coverage)',
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
            l10n?.ls_coverage_saved ?? 'Coverage saved',
          ),
          child: Text(l10n?.ls_save_coverage ?? 'Save coverage'),
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
