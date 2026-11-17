import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresDriversScreen extends StatefulWidget {
  const StoresDriversScreen({super.key});
  @override
  State<StoresDriversScreen> createState() => _StoresDriversScreenState();
}

class _StoresDriversScreenState extends State<StoresDriversScreen> {
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
      final Map<String, dynamic> body = await r.drivers();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] ?? body['drivers'] ?? body['results'] ?? const <dynamic>[])
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

  Future<void> _suspend(BuildContext context, Map<String, dynamic> driver) async {
    final String? id = driver['_id']?.toString() ?? driver['id']?.toString();
    if (id == null) return;
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String doneMessage = AppLocalizations.of(context)!.storesMsgDriverSuspended;
    try {
      await repo.suspendDriver(id, 'suspended');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
      _load();
    } on Object catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reactivate(BuildContext context, Map<String, dynamic> driver) async {
    final String? id = driver['_id']?.toString() ?? driver['id']?.toString();
    if (id == null) return;
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String doneMessage = AppLocalizations.of(context)!.storesMsgDriverReactivated;
    try {
      await repo.reactivateDriver(id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
      _load();
    } on Object catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitleDrivers)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(l10n.storesNoDrivers))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> driver = _rows[index];
                        final bool active = driver['status'] != 'suspended';
                        final String status = '${driver['status'] ?? ''}';
                        return Semantics(
                          label: '${driver['name'] ?? driver['driverCode'] ?? l10n.storesFallbackDriver}',
                          child: ListTile(
                            leading: Icon(
                              active ? Icons.pedal_bike : Icons.pedal_bike_outlined,
                              color: active ? null : AppColors.grey,
                            ),
                            title: Text('${driver['name'] ?? driver['driverCode'] ?? l10n.storesFallbackDriver}'),
                            subtitle: Text(status),
                            trailing: active
                                ? TextButton(
                                    onPressed: () => _suspend(context, driver),
                                    child: Text(l10n.storesActionSuspend),
                                  )
                                : TextButton(
                                    onPressed: () => _reactivate(context, driver),
                                    child: Text(l10n.storesActionReactivate),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
