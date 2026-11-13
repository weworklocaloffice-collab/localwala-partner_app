import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerReturnsDedicatedScreen extends StatefulWidget {
  const StoresPartnerReturnsDedicatedScreen({super.key});
  @override
  State<StoresPartnerReturnsDedicatedScreen> createState() => _StoresPartnerReturnsDedicatedScreenState();
}

class _StoresPartnerReturnsDedicatedScreenState extends State<StoresPartnerReturnsDedicatedScreen> {
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
      final Map<String, dynamic> body = await r.returns();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] ?? body['returns'] ?? body['results'] ?? const <dynamic>[])
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.storesTitleReturns)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.storesNoReturns))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> r = _rows[index];
                        return ListTile(
                          leading: const Icon(Icons.assignment_return_outlined),
                          title: Text('${r['status'] ?? AppLocalizations.of(context)!.storesFallbackReturn}'),
                          subtitle: Text('${r['reason'] ?? ''}'),
                        );
                      },
                    ),
    );
  }
}
