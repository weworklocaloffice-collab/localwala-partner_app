import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:flutter/material.dart';

/// Dairy-only order hours, order cut-off, and the approved localities the outlet
/// currently elects to serve. New localities remain admin-approved first.
class PartnerAvailabilityScreen extends StatefulWidget {
  const PartnerAvailabilityScreen({super.key, this.repository});

  final PartnerRepository? repository;

  @override
  State<PartnerAvailabilityScreen> createState() => _PartnerAvailabilityScreenState();
}

class _PartnerAvailabilityScreenState extends State<PartnerAvailabilityScreen> {
  static const List<String> _days = <String>[
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  late final PartnerRepository _repository = widget.repository ?? PartnerRepository();
  bool _loading = true;
  bool _saving = false;
  bool _acceptingOrders = true;
  bool _hoursConfigured = false;
  bool _hoursChanged = false;
  bool _specialHoursChanged = false;
  bool _serviceabilityConfigured = false;
  String? _primaryLocalityId;
  String _timezone = 'Asia/Kolkata';
  String? _cutoff;
  String? _error;
  Map<String, dynamic> _orderAvailability = <String, dynamic>{};
  List<Map<String, dynamic>> _approvedLocalities = <Map<String, dynamic>>[];
  final Set<String> _serviceable = <String>{};
  late List<Map<String, dynamic>> _hours;
  List<Map<String, dynamic>> _specialHours = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _hours = _emptyWeek();
    _load();
  }

  List<Map<String, dynamic>> _emptyWeek() => List<Map<String, dynamic>>.generate(
        7,
        (int day) => <String, dynamic>{'day': day, 'isOpen': false},
      );

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  String _id(Map<String, dynamic> row) => (row['id'] ?? row['_id'] ?? '').toString();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final DioApiResponse response = await _repository.availability();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() { _loading = false; _error = 'Could not load Dairy business availability.'; });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> settings = _map(body['settings']);
    final List<Map<String, dynamic>> schedule = (settings['operatingHours'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final List<Map<String, dynamic>> specialHours = (settings['specialHours'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
    final List<Map<String, dynamic>> localities = (body['approvedLocalities'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final Set<String> savedIds = (settings['serviceableLocalities'] as List? ?? const <dynamic>[])
        .map((dynamic id) => id.toString())
        .toSet();
    setState(() {
      _loading = false;
      _acceptingOrders = settings['acceptingOrders'] != false;
      _timezone = settings['timezone']?.toString() ?? 'Asia/Kolkata';
      _cutoff = settings['orderCutoffTime']?.toString();
      _orderAvailability = _map(settings['orderAvailability']);
      _hoursConfigured = schedule.length == 7;
      _hoursChanged = false;
      _specialHoursChanged = false;
      _specialHours = specialHours;
      _hours = _emptyWeek();
      for (final Map<String, dynamic> row in schedule) {
        final int? day = int.tryParse(row['day']?.toString() ?? '');
        if (day != null && day >= 0 && day < 7) _hours[day] = row;
      }
      _approvedLocalities = localities;
      _primaryLocalityId = settings['primaryLocalityId']?.toString();
      _serviceabilityConfigured = settings['serviceabilityConfigured'] == true;
      _serviceable
        ..clear()
        ..addAll(_serviceabilityConfigured ? savedIds : localities.map(_id));
    });
  }

  Future<void> _chooseTime(int day, String field) async {
    final String current = _hours[day][field]?.toString() ?? (field == 'opensAt' ? '06:00' : '21:00');
    final List<String> parts = current.split(':');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hoursChanged = true;
      _hoursConfigured = true;
      _hours[day][field] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _chooseCutoff() async {
    final String current = _cutoff ?? '21:00';
    final List<String> parts = current.split(':');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null && mounted) {
      setState(() => _cutoff = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _addSpecialHours() async {
    if (_specialHours.length >= 90) {
      _message('You can configure up to 90 special dates. Remove an old date first.');
      return;
    }
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final String dateKey = date.toIso8601String().split('T').first;
    if (_specialHours.any((Map<String, dynamic> row) => row['date'] == dateKey)) {
      _message('Special hours are already set for that date.');
      return;
    }
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => _SpecialHoursDialog(date: date),
    );
    if (result == null || !mounted) return;
    setState(() {
      _specialHours.add(<String, dynamic>{'date': dateKey, ...result});
      _specialHours.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['date'] as String).compareTo(b['date'] as String));
      _specialHoursChanged = true;
    });
  }

  String _specialDateLabel(String? value) {
    final DateTime? date = value == null ? null : DateTime.tryParse(value);
    return date == null ? (value ?? 'Special date') : MaterialLocalizations.of(context).formatFullDate(date);
  }

  Future<void> _save() async {
    if (_saving) return;
    for (final Map<String, dynamic> row in _hours) {
      if (row['isOpen'] == true &&
          (row['opensAt'] == null || row['closesAt'] == null || row['opensAt'].toString().compareTo(row['closesAt'].toString()) >= 0)) {
        _message('${_days[row['day'] as int]} must close after it opens.');
        return;
      }
    }
    setState(() => _saving = true);
    final Map<String, dynamic> payload = <String, dynamic>{
      'acceptingOrders': _acceptingOrders,
      'serviceableLocalities': _serviceable.toList(),
      if (_hoursChanged || _hoursConfigured) 'operatingHours': _hours,
      if (_hoursChanged || _hoursConfigured) 'timezone': _timezone,
      if (_specialHoursChanged) 'specialHours': _specialHours,
      'orderCutoffTime': _cutoff,
    };
    final DioApiResponse response = await _repository.updateAvailability(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.errorType != NetErrorType.none) {
      final String message = (response.response?.data is Map)
          ? ((response.response!.data as Map)['message']?.toString() ?? 'Availability settings could not be saved.')
          : 'Availability settings could not be saved.';
      _message(message);
      return;
    }
    _serviceabilityConfigured = true;
    _hoursConfigured = _hoursChanged || _hoursConfigured;
    _hoursChanged = false;
    _message('Dairy availability settings saved.');
    await _load();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _timeLabel(String? value) {
    if (value == null) return 'Set time';
    final List<String> parts = value.split(':');
    final TimeOfDay time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  String get _availabilityStatus {
    switch (_orderAvailability['reason']) {
      case 'paused':
        return 'Paused by your outlet';
      case 'closed_today':
        return 'Closed for today';
      case 'special_closed':
        return 'Closed for a special date';
      case 'outside_hours':
        return 'Outside your business hours';
      case 'cutoff_passed':
        return 'Today’s order cut-off has passed';
      case 'open':
        return 'Customers can place Dairy orders now';
      default:
        return 'Current order status is unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business availability')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _orderAvailability['canAcceptOrders'] == true
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                        ),
                        title: Text(
                          _orderAvailability['canAcceptOrders'] == true
                              ? 'Open for orders now'
                              : 'Not accepting new orders now',
                        ),
                        subtitle: Text(
                          '$_availabilityStatus${_orderAvailability['localTime'] == null ? '' : ' · ${_orderAvailability['localTime']} $_timezone'}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: SwitchListTile.adaptive(
                        value: _acceptingOrders,
                        onChanged: _saving ? null : (bool value) => setState(() => _acceptingOrders = value),
                        title: const Text('Accepting new orders'),
                        subtitle: Text(_acceptingOrders ? 'Customers can order during your open hours.' : 'New Dairy orders are paused for all localities.'),
                        secondary: const Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text('Business hours', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(_hoursConfigured ? 'Local time · $_timezone' : 'No weekly hours configured yet. Until you set them, only the order pause and cut-off are enforced.'),
                          if (!_hoursConfigured) ...<Widget>[const SizedBox(height: 8), const Text('Select the days you operate, then set opening and closing times. No hours are assumed.'), const SizedBox(height: 8)],
                          ..._hours.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                            final int day = entry.key;
                            final Map<String, dynamic> row = entry.value;
                            final bool isOpen = row['isOpen'] == true;
                            return Column(children: <Widget>[
                              if (day > 0) const Divider(height: 1),
                              Row(children: <Widget>[
                                SizedBox(width: 44, child: Text(_days[day].substring(0, 3))),
                                Switch.adaptive(value: isOpen, onChanged: _saving ? null : (bool value) => setState(() {
                                  _hoursChanged = true;
                                  _hoursConfigured = true;
                                  row['isOpen'] = value;
                                  if (value) {
                                    row['opensAt'] ??= '06:00';
                                    row['closesAt'] ??= '21:00';
                                  }
                                })),
                                if (!isOpen) Expanded(child: Text(_hoursConfigured ? 'Closed' : 'Not set')) else ...<Widget>[
                                  Expanded(child: TextButton(onPressed: _saving ? null : () => _chooseTime(day, 'opensAt'), child: Text(_timeLabel(row['opensAt']?.toString())))),
                                  const Text('–'),
                                  Expanded(child: TextButton(onPressed: _saving ? null : () => _chooseTime(day, 'closesAt'), child: Text(_timeLabel(row['closesAt']?.toString())))),
                                ],
                              ]),
                            ]);
                          }),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(child: ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Daily order cut-off'),
                      subtitle: Text(_cutoff == null ? 'No cut-off configured' : 'Orders stop at ${_timeLabel(_cutoff)} ($_timezone)'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        TextButton(onPressed: _saving ? null : _chooseCutoff, child: Text(_cutoff == null ? 'Set' : 'Change')),
                        if (_cutoff != null) IconButton(tooltip: 'Clear cut-off', onPressed: _saving ? null : () => setState(() => _cutoff = null), icon: const Icon(Icons.close)),
                      ]),
                    )),
                    const SizedBox(height: 12),
                    Card(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Row(children: <Widget>[
                          Expanded(child: Text('Special hours and holidays', style: Theme.of(context).textTheme.titleMedium)),
                          IconButton(onPressed: _saving ? null : _addSpecialHours, tooltip: 'Add special date', icon: const Icon(Icons.add_circle_outline)),
                        ]),
                        const Text('Add holiday closures or one-off opening hours. These dates override your weekly schedule.'),
                        if (_specialHours.isEmpty)
                          const Padding(padding: EdgeInsets.only(top: 12), child: Text('No holiday exceptions scheduled.'))
                        else ..._specialHours.map((Map<String, dynamic> row) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(row['isClosed'] == true ? Icons.event_busy_outlined : Icons.event_available_outlined),
                          title: Text(_specialDateLabel(row['date']?.toString())),
                          subtitle: Text(row['isClosed'] == true
                              ? (row['label']?.toString().isNotEmpty == true ? 'Closed · ${row['label']}' : 'Closed all day')
                              : '${_timeLabel(row['opensAt']?.toString())} – ${_timeLabel(row['closesAt']?.toString())}${row['label']?.toString().isNotEmpty == true ? ' · ${row['label']}' : ''}'),
                          trailing: IconButton(
                            tooltip: 'Remove special date',
                            onPressed: _saving ? null : () => setState(() {
                              _specialHours.removeWhere((Map<String, dynamic> item) => item['date'] == row['date']);
                              _specialHoursChanged = true;
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        )),
                      ]),
                    )),
                    const SizedBox(height: 16),
                    Text('Approved delivery localities', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text('Only localities approved by the platform can be enabled here. Request new localities from Delivery area.'),
                    if (_approvedLocalities.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No approved delivery localities are available yet.')))
                    else
                      Card(child: Column(children: _approvedLocalities.map((Map<String, dynamic> locality) {
                        final String id = _id(locality);
                        final bool isPrimary = id.isNotEmpty && id == _primaryLocalityId;
                        return CheckboxListTile(
                          value: _serviceable.contains(id),
                          onChanged: _saving || isPrimary ? null : (bool? selected) => setState(() {
                            if (selected == true) {
                              _serviceable.add(id);
                            } else {
                              _serviceable.remove(id);
                            }
                          }),
                          title: Text('${locality['name']?.toString() ?? 'Locality'}${isPrimary ? ' · Primary locality' : ''}'),
                          subtitle: Text(isPrimary
                              ? 'Your registered outlet locality must remain enabled. Pause all orders to stop service everywhere.'
                              : _serviceable.contains(id) ? 'Customers here can place Dairy orders.' : 'Currently paused for this locality.'),
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: isPrimary ? const Icon(Icons.lock_outline, size: 18) : null,
                        );
                      }).toList())),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Text('Save availability'),
                    ),
                  ],
                ),
    );
  }
}

class _SpecialHoursDialog extends StatefulWidget {
  const _SpecialHoursDialog({required this.date});
  final DateTime date;

  @override
  State<_SpecialHoursDialog> createState() => _SpecialHoursDialogState();
}

class _SpecialHoursDialogState extends State<_SpecialHoursDialog> {
  bool _closed = true;
  TimeOfDay _opensAt = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closesAt = const TimeOfDay(hour: 21, minute: 0);
  final TextEditingController _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  String _clock(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _chooseTime(bool opening) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: opening ? _opensAt : _closesAt,
    );
    if (time == null || !mounted) return;
    setState(() { if (opening) { _opensAt = time; } else { _closesAt = time; } });
  }

  void _save() {
    if (!_closed && _clock(_opensAt).compareTo(_clock(_closesAt)) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closing time must be after opening time.')));
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'isClosed': _closed,
      if (!_closed) 'opensAt': _clock(_opensAt),
      if (!_closed) 'closesAt': _clock(_closesAt),
      if (_label.text.trim().isNotEmpty) 'label': _label.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(MaterialLocalizations.of(context).formatFullDate(widget.date)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: _closed, onChanged: (bool value) => setState(() => _closed = value), title: const Text('Closed all day')),
      if (!_closed) Row(children: <Widget>[
        Expanded(child: TextButton.icon(onPressed: () => _chooseTime(true), icon: const Icon(Icons.login), label: Text(MaterialLocalizations.of(context).formatTimeOfDay(_opensAt)))),
        Expanded(child: TextButton.icon(onPressed: () => _chooseTime(false), icon: const Icon(Icons.logout), label: Text(MaterialLocalizations.of(context).formatTimeOfDay(_closesAt)))),
      ]),
      TextField(controller: _label, maxLength: 100, decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Public holiday, maintenance')),
    ])),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save date')),
    ],
  );
}
