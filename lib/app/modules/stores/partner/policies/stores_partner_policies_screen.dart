import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerPoliciesScreen extends StatefulWidget {
  const StoresPartnerPoliciesScreen({super.key});
  @override
  State<StoresPartnerPoliciesScreen> createState() => _StoresPartnerPoliciesScreenState();
}

class _StoresPartnerPoliciesScreenState extends State<StoresPartnerPoliciesScreen> {
  StoresPartnerRepository? _repo;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load() async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final Map<String, dynamic> body = await r.listPolicies();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] ?? body['results'] ?? body['policies'] ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
            .toList();
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitlePolicies)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(l10n.storesNoPolicies))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> p = _rows[index];
                        return ListTile(
                          leading: const Icon(Icons.policy_outlined),
                          title: Text('${p['title'] ?? p['name'] ?? AppLocalizations.of(context)!.storesFallbackPolicy}'),
                          subtitle: Text('${p['status'] ?? ''}'),
                        );
                      },
                    ),
    );
  }
}
