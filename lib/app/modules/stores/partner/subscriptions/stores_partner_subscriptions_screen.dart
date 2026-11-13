import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:flutter/material.dart';

class StoresPartnerSubscriptionsScreen extends StatefulWidget {
  const StoresPartnerSubscriptionsScreen({super.key});

  @override
  State<StoresPartnerSubscriptionsScreen> createState() =>
      _StoresPartnerSubscriptionsScreenState();
}

class _StoresPartnerSubscriptionsScreenState
    extends State<StoresPartnerSubscriptionsScreen> {
  StoresPartnerRepository? _repo;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  int _page = 1;
  int _totalPages = 1;
  String _status = '';

  bool _demandLoading = true;
  String? _demandError;
  List<Map<String, dynamic>> _demand = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
    _loadDemand();
  }

  Future<void> _load({bool more = false}) async {
    if (more) setState(() => _loading = true);
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final Map<String, dynamic> body = await r.customerSubscriptions(
        status: _status.isEmpty ? null : _status,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
            .toList();
        _totalPages = (body['totalPages'] as num?)?.toInt() ?? 1;
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

  Future<void> _refresh() async {
    setState(() => _page = 1);
    await _load();
  }

  Future<void> _loadDemand() async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final Map<String, dynamic> body = await r.subscriptionDemand();
      if (!mounted) return;
      setState(() {
        _demand = (body['items'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
            .toList();
        _demandLoading = false;
        _demandError = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _demandLoading = false;
        _demandError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.storesTitleCustomerSubscriptions),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: l10n.storesSubscribers),
              Tab(text: l10n.storesNext7Days),
              Tab(text: l10n.storesSkipped),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _subscribersTab(),
            _demandTab(),
            _skippedTab(),
          ],
        ),
      ),
    );
  }

  Widget _subscribersTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refresh, child: Text(l10n.storesRetry)),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
           children: <Widget>[
             SizedBox(height: 120),
             Center(child: Text(AppLocalizations.of(context)!.storesNoSubscriptions)),
           ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        itemCount: _rows.length + (_page < _totalPages ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _rows.length) {
            return ListTile(
              title: Text(l10n.storesLoadMore),
              onTap: () {
                setState(() => _page += 1);
                _load(more: true);
              },
            );
          }
          final Map<String, dynamic> s = _rows[index];
          final dynamic customer = s['customer'];
          final String name = customer is Map
              ? '${customer['name'] ?? customer['phone'] ?? ''}'
              : '${s['customer'] ?? ''}';
          return ListTile(
            leading: const Icon(Icons.autorenew_outlined),
            title: Text(name.isEmpty ? 'Subscription' : name),
            subtitle: Text(
              '${s['status'] ?? ''}'
              '${s['nextOccurrenceDate'] != null ? ' · next ${s['nextOccurrenceDate']}' : ''}',
            ),
            trailing: Text('${s['items'] is List ? (s['items'] as List).length : 0} ${AppLocalizations.of(context)!.storesLabelItems}'),
          );
        },
      ),
    );
  }

  Widget _skippedTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime now = DateTime.now();
    final DateTime horizon = now.add(const Duration(days: 7));
    final List<Map<String, dynamic>> skipped = _rows.where((Map<String, dynamic> s) {
      final dynamic raw = s['skipDates'];
      if (raw is! List) return false;
      for (final dynamic d in raw) {
        DateTime? dt;
        if (d is String) dt = DateTime.tryParse(d);
        if (d is Map) dt = DateTime.tryParse('${d['date'] ?? d['_id'] ?? ''}');
        if (dt != null && !dt.isBefore(now) && !dt.isAfter(horizon)) return true;
      }
      return false;
    }).toList();
    if (skipped.isEmpty) {
      return Center(child: Text(l10n.storesNoSkipped));
    }
    return ListView.separated(
      itemCount: skipped.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> s = skipped[index];
        final dynamic customer = s['customer'];
        final String name = customer is Map
            ? '${customer['name'] ?? customer['phone'] ?? ''}'
            : '${s['customer'] ?? ''}';
        return ListTile(
          leading: const Icon(Icons.event_busy_outlined),
          title: Text(name.isEmpty ? 'Subscription' : name),
          subtitle: Text('${s['status'] ?? ''}'),
        );
      },
    );
  }

  Widget _demandTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_demandLoading) return const Center(child: CircularProgressIndicator());
    if (_demandError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_demandError!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadDemand, child: Text(AppLocalizations.of(context)!.storesRetry)),
          ],
        ),
      );
    }
    if (_demand.isEmpty) {
      return Center(child: Text(l10n.storesNoUpcoming));
    }
    return ListView.separated(
      itemCount: _demand.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> d = _demand[index];
        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text('${d['productName'] ?? d['variantName'] ?? AppLocalizations.of(context)!.storesFallbackVariant}'),
          subtitle: Text('${d['variantName'] ?? ''}'),
          trailing: Text('${d['quantity']} units · ${d['subscriptions']} subs'),
        );
      },
    );
  }
}
