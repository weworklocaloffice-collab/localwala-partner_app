/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:flutter/material.dart';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/jhatka/partner/dashboard/jhatka_dashboard_repository.dart';
import 'package:partner/app/modules/jhatka/partner/session/outlet_switcher_sheet.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The outlet's daily numbers.
///
/// ## What this screen is for
///
/// An owner opening the partner app in the morning wants three things: how much came
/// in, how much was wasted, and whether anything is about to bite them. Everything
/// else is a tab away.
///
/// ## The three numbers that are easy to misread
///
///   **Absorbed overcharge** is weight ABOVE the estimate that LocalWala paid for and
///   charged nobody (BR-06). It is not revenue and it is not a tip to the outlet — it
///   is cost. A rising figure means the COD ceiling is under-priced or someone is
///   over-reporting preparation volume.
///
///   **Refund rate** is refunds over gross. §7.1 notes a variant above about 2% will
///   refund every week, so this is a leading indicator, not a lagging cost.
///
///   **Contribution** is gross minus wastage. It is NOT profit: cost of goods and
///   operator payouts are settled separately on a settlement cadence. The card says so,
///   because an owner comparing it to a bank balance will otherwise conclude the
///   settlement is wrong.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final JhatkaDashboardRepository _repository = JhatkaDashboardRepository();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = <String, dynamic>{};

  /// Window picker. Empty means the service's own 30-day default.
  DateTimeRange _window = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _useWindow = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final DioApiResponse response = await _repository.analytics(
      from: _useWindow ? _isoDate(_window.start) : null,
      to: _useWindow ? _isoDate(_window.end) : null,
    );

    if (!mounted) {
      return;
    }

    // `errorType` first, then the body — the same order every other Jhatka screen uses.
    // Checking the body before the error flag is how a failed request with an empty
    // body renders as "loaded, no data".
    if (response.errorType != NetErrorType.none) {
      final Map<String, dynamic> body = decodeBody(response);
      final Map<String, dynamic> extra = body['extra'] is Map<String, dynamic>
          ? body['extra'] as Map<String, dynamic>
          : <String, dynamic>{};
      final String outletStatus = '${extra['status'] ?? ''}';
      final String message =
          outletStatus == 'pending_approval' || outletStatus == 'draft'
          ? 'Your outlet is awaiting approval. Submit your FSSAI licence from Compliance while you wait.'
          : outletStatus == 'suspended'
          ? 'This outlet is suspended. Open Compliance for the reason and next steps.'
          : outletStatus == 'closed'
          ? 'This outlet is closed.'
          : 'Could not load the dashboard.';
      setState(() {
        _error = message;
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _summary =
          (body['analytics'] as Map<String, dynamic>?) ??
          (body['summary'] as Map<String, dynamic>?) ??
          body;
      _isLoading = false;
    });
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Rupees -> display. The analytics service returns RUPEES, so this goes through
  /// `formatRupees` and NOT `formatPaise`.
  static String _rs(dynamic rupees) =>
      rupees == null ? '--' : formatRupees((rupees as num));

  static int _count(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;

  Future<void> _pickWindow() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _window,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _window = picked;
      _useWindow = true;
    });
    _load();
  }

  void _resetWindow() {
    setState(() => _useWindow = false);
    _load();
  }

  List<Widget> _buildOrderCards() {
    final Map<String, dynamic> orders =
        (_summary['orders'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return <Widget>[
      _MetricCard(
        label: AppLocalizations.of(context)!.navOrders,
        value: '${_count(orders['count'])}',
        hint: AppLocalizations.of(context)!.jhatkaInWindow,
      ),
      _MetricCard(
        label: AppLocalizations.of(context)!.jhatkaGrossCollected,
        value: _rs(
          _summary['grossCollected'] ??
              _asMap(_summary, 'contribution')['grossCollected'],
        ),
        hint: AppLocalizations.of(context)!.jhatkaEstimatedMinusRefunds,
      ),
      _MetricCard(
        label: AppLocalizations.of(context)!.jhatkaRefunded,
        value: _rs(orders['refundedTotal']),
        hint: AppLocalizations.of(context)!.jhatkaEveryRefundIsDocument,
      ),
      _MetricCard(
        label: AppLocalizations.of(context)!.jhatkaNavWastage,
        value: _rs(_asMap(_summary, 'contribution')['wastageValue']),
        hint: AppLocalizations.of(
          context,
        )!.jhatkaWastageRecords(_count(_asMap(_summary, 'wastage')['count'])),
      ),
    ];
  }

  static Map<String, dynamic> _asMap(Map<String, dynamic> src, String key) {
    final dynamic v = src[key];
    return v is Map<String, dynamic> ? v : <String, dynamic>{};
  }

  Widget _buildContributionNotice() {
    final Map<String, dynamic> contribution = _asMap(_summary, 'contribution');
    final num absorbed = (contribution['absorbedOvercharge'] as num?) ?? 0;
    final num rate = (contribution['refundRate'] as num?) ?? 0;

    if (absorbed <= 0 && rate <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: absorbed > 0 ? Colors.amber.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (absorbed > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Absorbed overcharge ${formatRupees(absorbed)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (absorbed > 0)
              Text(
                'Weight above the estimate that LocalWala paid for and charged nobody. '
                'This is cost, not revenue — a rising figure means the COD ceiling is '
                'under-priced or preparation volume is over-reported.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (rate > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Refund rate ${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            if (rate > 2)
              Text(
                'Above about 2%, a variant will refund every single week. Worth '
                'checking whether the weight tolerance or the yield spec is wrong.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleStrip() {
    final Map<String, dynamic> orders = _asMap(_summary, 'orders');
    final dynamic byLifecycle = orders['byLifecycle'];
    if (byLifecycle is! Map) {
      return const SizedBox.shrink();
    }
    final List<MapEntry<dynamic, dynamic>> rows = byLifecycle.entries.toList()
      ..sort(
        (MapEntry<dynamic, dynamic> a, MapEntry<dynamic, dynamic> b) =>
            _count(b.value).compareTo(_count(a.value)),
      );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Orders by stage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: rows
                  .map(
                    (MapEntry<dynamic, dynamic> row) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${row.key}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${_count(row.value)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockWarnings() {
    final Map<String, dynamic> inventory = _asMap(_summary, 'inventory');
    final int low = _count(inventory['lowStockCount']);
    final int expired = _count(inventory['expiredCount']);

    if (low == 0 && expired == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (expired > 0)
              Text(
                '$expired batch(es) past their use-by date',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            if (low > 0)
              Text(
                '$low product(s) at or below the reorder level',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.realEstateNavDashboard),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context)!.jhatkaActionSwitchCounter,
            icon: const Icon(Icons.store_outlined),
            onPressed: () async {
              final String? switched = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const OutletSwitcherSheet(),
              );
              // A switch changes every number on this screen and every list
              // behind the tabs. Reload here; the tabs reload on next visit.
              if (switched != null && switched.isNotEmpty && mounted) {
                await _load();
              }
            },
          ),
          IconButton(
            tooltip: _useWindow ? 'Window: custom' : 'Window: last 30 days',
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _pickWindow,
          ),
          if (_useWindow)
            TextButton(
              onPressed: _resetWindow,
              child: Text(AppLocalizations.of(context)!.jhatkaActionReset),
            ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.storesActionRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _buildContributionNotice(),
                  _buildStockWarnings(),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _buildOrderCards(),
                  ),
                  const SizedBox(height: 16),
                  _buildLifecycleStrip(),
                  const SizedBox(height: 16),
                  Text(
                    'Contribution excludes cost of goods and operator payouts — '
                    'those are settled separately.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
