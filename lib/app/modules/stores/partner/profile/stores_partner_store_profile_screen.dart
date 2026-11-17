import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerStoreProfileScreen extends StatefulWidget {
  const StoresPartnerStoreProfileScreen({super.key});
  @override
  State<StoresPartnerStoreProfileScreen> createState() => _StoresPartnerStoreProfileScreenState();
}

class _StoresPartnerStoreProfileScreenState extends State<StoresPartnerStoreProfileScreen> {
  StoresPartnerRepository? _repo;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _outlet = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load() async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final List<Map<String, dynamic>> outlets = await r.myOutlets();
      if (outlets.isEmpty) { setState(() { _loading = false; _error = 'No outlet'; }); return; }
      final String id = '${outlets.first['_id'] ?? outlets.first['id'] ?? ''}';
      if (id.isEmpty) { setState(() { _loading = false; _error = 'No outlet'; }); return; }
      final Map<String, dynamic> detail = await r.outletDetail(id);
      if (!mounted) return;
      setState(() { _outlet = detail; _loading = false; _error = null; });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitleStoreProfile)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    for (final MapEntry<String, dynamic> e in _outlet.entries)
                      ListTile(title: Text(e.key), subtitle: Text('${e.value}')),
                  ],
                ),
    );
  }
}
