import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerDispatchScreen extends StatefulWidget {
  const StoresPartnerDispatchScreen({super.key});
  @override
  State<StoresPartnerDispatchScreen> createState() => _StoresPartnerDispatchScreenState();
}

class _StoresPartnerDispatchScreenState extends State<StoresPartnerDispatchScreen> {
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
      final Map<String, dynamic> body = await r.deliveries();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] ?? body['deliveries'] ?? body['results'] ?? const <dynamic>[])
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
      appBar: AppBar(title: Text(l10n.storesTitleDispatch)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(l10n.storesNoDispatch))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> o = _rows[index];
                        return Semantics(
                          label: '${o['orderNo'] ?? '-'}',
                          child: ListTile(
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text(l10n.storesOrderNumber('${o['orderNo'] ?? '-'}')),
                            subtitle: Text('${o['lifecycle'] ?? ''}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
