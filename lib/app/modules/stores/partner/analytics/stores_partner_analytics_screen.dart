import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerAnalyticsScreen extends StatefulWidget {
  const StoresPartnerAnalyticsScreen({super.key});
  @override
  State<StoresPartnerAnalyticsScreen> createState() => _StoresPartnerAnalyticsScreenState();
}

class _StoresPartnerAnalyticsScreenState extends State<StoresPartnerAnalyticsScreen> {
  StoresPartnerRepository? _repo;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load() async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final Map<String, dynamic> body = await r.chainAnalytics();
      if (!mounted) return;
      setState(() { _data = body; _loading = false; _error = null; });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitleAnalytics)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    for (final MapEntry<String, dynamic> e in _data.entries)
                      ListTile(
                        title: Text(e.key),
                        subtitle: Text('${e.value}'),
                      ),
                  ],
                ),
    );
  }
}
