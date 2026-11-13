import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';

class PartnerReportScreen extends StatefulWidget {
  const PartnerReportScreen({super.key});
  @override
  State<PartnerReportScreen> createState() => _PartnerReportScreenState();
}

class _PartnerReportScreenState extends State<PartnerReportScreen> {
  final PartnerRepository _repository = PartnerRepository();
  int _days = 30;
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic> _report = <String, dynamic>{};
  String get _from => DateTime.now().subtract(Duration(days: _days - 1)).toUtc().toIso8601String();
  String get _to => DateTime.now().toUtc().toIso8601String();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final DioApiResponse response = await _repository.dairySalesReport(from: _from, to: _to);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() { _loading = false; _error = 'Could not load this report. Check your connection and try again.'; });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _report = body['report'] is Map ? Map<String, dynamic>.from(body['report'] as Map) : <String, dynamic>{};
    });
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final DioApiResponse response = await _repository.dairySalesCsv(from: _from, to: _to);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none || response.body == null) {
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create the sales export.')));
      return;
    }
    final String fileName = 'dairy-sales-${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save sales report', fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(response.body!)),
    );
    if (!mounted) return;
    setState(() => _exporting = false);
    if (path != null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sales report saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> totals = _report['totals'] is Map
        ? Map<String, dynamic>.from(_report['totals'] as Map) : <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Sales reports'), actions: <Widget>[
        IconButton(onPressed: _exporting ? null : _export, tooltip: 'Export CSV', icon: _exporting
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_outlined)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 7, label: Text('7 days')),
                ButtonSegment<int>(value: 30, label: Text('30 days')),
                ButtonSegment<int>(value: 90, label: Text('90 days')),
              ],
              selected: <int>{_days},
              onSelectionChanged: (Set<int> value) { setState(() => _days = value.first); _load(); },
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
              _metric('Completed orders', '${totals['completedOrders'] ?? 0}', Icons.receipt_long_outlined),
              _metric('Delivered order value', '₹${totals['deliveredOrderValue'] ?? 0}', Icons.payments_outlined),
              _metric('Discounts', '₹${totals['discounts'] ?? 0}', Icons.local_offer_outlined),
              _metric('Net product sales', '₹${totals['netProductSales'] ?? 0}', Icons.trending_up),
            ]),
            const SizedBox(height: 20),
            _section('Daily sales', _list(_report['dailyTrend'], (Map<String, dynamic> row) => ListTile(
              dense: true, title: Text(row['date']?.toString() ?? ''),
              subtitle: Text('${row['orders'] ?? 0} orders · discounts ₹${row['discounts'] ?? 0}'),
              trailing: Text('₹${row['sales'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ))),
            _section('Top products', _list(_report['topProducts'], (Map<String, dynamic> row) => ListTile(
              dense: true, title: Text(row['name']?.toString() ?? 'Product'), subtitle: Text('${row['units'] ?? 0} units'), trailing: Text('₹${row['grossSales'] ?? 0}'),
            ))),
            _section('Coupon impact', _list(_report['couponImpact'], (Map<String, dynamic> row) => ListTile(
              dense: true, title: Text(row['code']?.toString() ?? ''), subtitle: Text('${row['redemptions'] ?? 0} redemptions'), trailing: Text('₹${row['discounts'] ?? 0}'),
            ))),
            _section('Settlement status', _list(_report['settlements'], (Map<String, dynamic> row) => ListTile(
              dense: true, title: Text(row['status']?.toString() ?? ''), subtitle: Text('${row['count'] ?? 0} settlements'), trailing: Text('₹${row['netAmount'] ?? 0}'),
            ))),
            const SizedBox(height: 12),
            Text('Sales include delivered Dairy orders for the selected period. Amounts are shown in rupees.', style: Theme.of(context).textTheme.bodySmall),
          ])),
    );
  }

  List<Widget> _list(dynamic rows, Widget Function(Map<String, dynamic>) builder) {
    if (rows is! List || rows.isEmpty) return const <Widget>[Padding(padding: EdgeInsets.all(16), child: Text('No report data for this period.'))];
    return rows.whereType<Map>().map((Map row) => builder(Map<String, dynamic>.from(row))).toList();
  }

  Widget _section(String title, List<Widget> children) => Card(child: Padding(
    padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), ...children,
    ]),
  ));

  Widget _metric(String label, String value, IconData icon) => SizedBox(width: 160, child: Card(child: Padding(
    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10),
      Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  )));
}
