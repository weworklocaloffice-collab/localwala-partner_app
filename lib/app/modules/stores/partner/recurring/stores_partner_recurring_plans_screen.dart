import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerRecurringPlansScreen extends StatefulWidget {
  const StoresPartnerRecurringPlansScreen({super.key});

  @override
  State<StoresPartnerRecurringPlansScreen> createState() =>
      _StoresPartnerRecurringPlansScreenState();
}

class _StoresPartnerRecurringPlansScreenState
    extends State<StoresPartnerRecurringPlansScreen> {
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
      final Map<String, dynamic> body = await r.listRecurringPlans();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
            .toList();
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _transition(String id, String status) async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      await r.transitionRecurringPlan(id, status);
      await _load();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.storesTitleRecurringPlans)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(l10n.storesNoRecurringPlans))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> p = _rows[index];
                        final String id = '${p['_id'] ?? p['id'] ?? ''}';
                        return ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text('${p['name'] ?? AppLocalizations.of(context)!.storesFallbackPlan}'),
                          subtitle: Text('${p['status'] ?? ''} · ${p['cadence'] ?? ''}'),
                          trailing: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              if (p['status'] == 'draft')
                                TextButton(onPressed: () => _transition(id, 'active'), child: Text(l10n.storesActivate)),
                              if (p['status'] == 'active')
                                TextButton(onPressed: () => _transition(id, 'paused'), child: Text(l10n.storesPause)),
                              if (p['status'] == 'paused')
                                TextButton(onPressed: () => _transition(id, 'active'), child: Text(l10n.storesResume)),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
