import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  String _filter = '';
  List<dynamic> _agreements = const <dynamic>[];

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
      final DioApiResponse response = await _repository.recurring(status: _filter);
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _agreements = body['results'] ?? body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: <String>['', 'active', 'paused', 'cancelled', 'completed']
                  .map((String s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.isEmpty ? 'All' : s[0].toUpperCase() + s.substring(1)),
                          selected: _filter == s,
                          onSelected: (_) {
                            setState(() => _filter = s);
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? LsErrorState(message: _error!, onRetry: _load)
                    : _agreements.isEmpty
                        ? const LsEmptyState(
                            icon: Icons.autorenew_outlined,
                            title: 'No recurring agreements yet',
                            subtitle: 'Agreements created by customers appear here.',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _agreements.length,
                              itemBuilder: (BuildContext context, int i) {
                                final dynamic a = _agreements[i];
                                final String status = '${a['status'] ?? ''}';
                                final String cadence = '${a['cadence'] ?? 'weekly'}';
                                final String next = '${a['nextOccurrenceDate'] ?? ''}';
                                final String nextShort = next.length >= 10 ? next.substring(0, 10) : next;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                'Recurring visit · $cadence',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            LsStatusBadge(status: status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Next: $nextShort · '
                                          'Labour ${a['labourAmount'] ?? 0} · Parts ${a['partsAmount'] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
