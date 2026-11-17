import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quotes = const <Map<String, dynamic>>[];

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
      final DioApiResponse response = await _repository.quotes();
      final Map<String, dynamic> body = decodeBody(response);
      final List<dynamic> raw =
          (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      setState(() {
        _quotes = raw.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _revise(Map<String, dynamic> quote) async {
    final TextEditingController labour = TextEditingController(
      text: '${quote['labourAmount'] ?? ''}',
    );
    final TextEditingController parts = TextEditingController(
      text: '${quote['partsAmount'] ?? ''}',
    );
    final TextEditingController notes = TextEditingController(
      text: '${quote['notes'] ?? ''}',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Revise quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: labour,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Labour amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: parts,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Parts amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.reviseQuote('${quote['id'] ?? quote['_id']}', <String, dynamic>{
        'labourAmount': int.tryParse(labour.text.trim()) ?? 0,
        'partsAmount': int.tryParse(parts.text.trim()) ?? 0,
        'note': notes.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote revised')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_quotes_title ?? 'Quotes'),
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
              ? LsErrorState(message: _error!, onRetry: _load)
              : _quotes.isEmpty
                  ? LsEmptyState(
                      icon: Icons.request_quote_outlined,
                      title: l10n?.ls_no_quotes ?? 'No quotes yet',
                      subtitle: 'Quotes submitted for bookings will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _quotes.length,
                        itemBuilder: (BuildContext context, int i) {
                          final Map<String, dynamic> q = _quotes[i];
                          final String status = '${q['status'] ?? ''}';
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
                                          'Labour ${q['labourAmount'] ?? 0} · Parts ${q['partsAmount'] ?? 0}',
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
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'v${q['version'] ?? 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (status == 'SUBMITTED')
                                        TextButton.icon(
                                          onPressed: () => _revise(q),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: Text(l10n?.ls_revise ?? 'Revise'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
