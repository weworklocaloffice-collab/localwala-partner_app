import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/core/services/razorpay_payment_service.dart';

/// Dairy-only paid placement booking. Admin review is required before payment.
class PartnerMarketingScreen extends StatefulWidget {
  const PartnerMarketingScreen({super.key, this.repository});
  final PartnerRepository? repository;

  @override
  State<PartnerMarketingScreen> createState() => _PartnerMarketingScreenState();
}

class _PartnerMarketingScreenState extends State<PartnerMarketingScreen> {
  late final PartnerRepository _repository = widget.repository ?? PartnerRepository();
  final RazorpayPaymentService _razorpay = RazorpayPaymentService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _packages = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _campaigns = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _coupons = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _localities = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
  Map<String, dynamic> _coverage = <String, dynamic>{};
  String? _packageId;
  String? _productId;
  String? _caption;
  final Set<String> _selectedLocalities = <String>{};
  DateTime _startsAt = DateTime.now().add(const Duration(minutes: 10));
  DateTime _couponEndsAt = DateTime.now().add(const Duration(days: 30));
  String _couponType = 'fixed';
  String _couponCode = '';
  String _couponTitle = '';
  String _couponDescription = '';
  String _couponValue = '';
  String _couponMaxDiscount = '';
  String _couponMinimum = '0';
  String _couponMaxRedemptions = '';

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
  List<Map<String, dynamic>> _rows(dynamic value) => value is List
      ? value.whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList()
      : <Map<String, dynamic>>[];
  Map<String, dynamic> _body(DioApiResponse response) {
    final String body = response.body ?? '';
    return body.isEmpty ? <String, dynamic>{} : _map(jsonDecode(body));
  }
  String _id(Map<String, dynamic> row) => (row['id'] ?? row['_id'] ?? '').toString();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _razorpay.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final List<DioApiResponse> responses = await Future.wait(<Future<DioApiResponse>>[
        _repository.marketingPackages(), _repository.marketingCampaigns(),
        _repository.coverage(), _repository.products(limit: 100),
        _repository.marketingCoupons(),
      ]);
      if (responses.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
        throw StateError('Promotions could not be loaded. Please try again.');
      }
      final Map<String, dynamic> packageBody = _body(responses[0]);
      final Map<String, dynamic> campaignBody = _body(responses[1]);
      final Map<String, dynamic> coverage = _body(responses[2]);
      final Map<String, dynamic> productBody = _body(responses[3]);
      final Map<String, dynamic> couponBody = _body(responses[4]);
      final List<Map<String, dynamic>> packages = _rows(packageBody['packages']);
      final List<Map<String, dynamic>> localities = _rows(coverage['activeLocalities']);
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _campaigns = _rows(campaignBody['campaigns']);
        _coverage = coverage;
        _localities = localities;
        _products = _rows(productBody['products'] ?? productBody['results']);
        _coupons = _rows(couponBody['coupons']);
        _packageId ??= packages.isEmpty ? null : _id(packages.first);
        if (_selectedLocalities.isEmpty && localities.length == 1) {
          _selectedLocalities.add(_id(localities.first));
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Map<String, dynamic>? get _selectedPackage {
    for (final Map<String, dynamic> row in _packages) {
      if (_id(row) == _packageId) return row;
    }
    return null;
  }

  Map<String, dynamic> _packageById(String? id) {
    for (final Map<String, dynamic> row in _packages) {
      if (_id(row) == id) return row;
    }
    return <String, dynamic>{};
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _chooseStart() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(context: context, initialDate: _startsAt,
      firstDate: now, lastDate: now.add(const Duration(days: 60)));
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt));
    if (time != null && mounted) {
      setState(() => _startsAt = DateTime(
      date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  Future<void> _createCampaign() async {
    final Map<String, dynamic>? package = _selectedPackage;
    final String targeting = package?['targetingLevel']?.toString() ?? '';
    final String placement = package?['placement']?.toString() ?? '';
    final List<String> localities = _selectedLocalities.toList();
    if (package == null || (_caption ?? '').trim().length < 2) {
      _message('Choose a package and enter a short campaign caption.'); return;
    }
    if (localities.isEmpty || (targeting == 'locality' && localities.length != 1)) {
      _message(targeting == 'locality' ? 'Choose exactly one approved locality.' : 'Choose approved localities.'); return;
    }
    if (targeting == 'zone' && _coverage['eligibleZone'] == null) {
      _message('There is no published delivery zone available for this outlet.'); return;
    }
    if (placement == 'featured_product' && (_productId == null || _productId!.isEmpty)) {
      _message('Choose the product to feature.'); return;
    }
    if (_startsAt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      _message('Schedule the campaign at least five minutes from now.'); return;
    }
    setState(() => _saving = true);
    try {
      final DioApiResponse response = await _repository.createMarketingCampaign(<String, dynamic>{
        'package': _packageId,
        'caption': _caption!.trim(),
        'startsAt': _startsAt.toUtc().toIso8601String(),
        'localities': localities,
        if (targeting == 'zone') 'zone': _id(_map(_coverage['eligibleZone'])),
        if (placement == 'featured_product') 'product': _productId,
      });
      if (response.errorType != NetErrorType.none) {
        throw StateError(_body(response)['message']?.toString() ?? 'Campaign request failed.');
      }
      _caption = '';
      _message('Campaign submitted for admin approval. Payment is enabled after approval.');
      await _load();
    } catch (error) { _message(error.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _chooseCouponEnd() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _couponEndsAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _couponEndsAt = DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  Future<void> _createCoupon() async {
    final double? value = double.tryParse(_couponValue);
    final double? minOrder = double.tryParse(_couponMinimum);
    final double? cap = _couponType == 'percentage' ? double.tryParse(_couponMaxDiscount) : null;
    if (_couponCode.trim().length < 2 || _couponTitle.trim().length < 2 || value == null || value <= 0 || minOrder == null ||
        (_couponType == 'percentage' && (value > 100 || cap == null || cap <= 0))) {
      _message('Enter a valid coupon code, title and discount. Percentage coupons need a maximum savings amount.');
      return;
    }
    final int? maxRedemptions = int.tryParse(_couponMaxRedemptions);
    setState(() => _saving = true);
    try {
      final DioApiResponse response = await _repository.createMarketingCoupon(<String, dynamic>{
        'code': _couponCode.trim().toUpperCase(),
        'title': _couponTitle.trim(),
        'description': _couponDescription.trim(),
        'discountType': _couponType,
        'discountValue': value,
        'minOrderAmount': minOrder,
        'maxDiscountAmount': ?cap,
        'startsAt': DateTime.now().add(const Duration(minutes: 1)).toUtc().toIso8601String(),
        'endsAt': _couponEndsAt.toUtc().toIso8601String(),
        if (maxRedemptions != null && maxRedemptions > 0) 'maxRedemptions': maxRedemptions,
      });
      if (response.errorType != NetErrorType.none) {
        throw StateError(_body(response)['message']?.toString() ?? 'Coupon submission failed.');
      }
      if (!mounted) return;
      _message('Coupon submitted for admin review. It will be usable after approval.');
      setState(() { _couponCode = ''; _couponTitle = ''; _couponDescription = ''; _couponValue = ''; _couponMaxDiscount = ''; _couponMaxRedemptions = ''; });
      await _load();
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _disableCoupon(Map<String, dynamic> coupon) async {
    final String id = _id(coupon);
    if (id.isEmpty) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Disable this coupon?'),
        content: const Text('Customers will no longer be able to apply it. Existing paid orders keep their recorded discount.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep coupon')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disable coupon')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final DioApiResponse response = await _repository.disableMarketingCoupon(id);
      if (response.errorType != NetErrorType.none) {
        throw StateError(_body(response)['message']?.toString() ?? 'Coupon could not be disabled.');
      }
      _message('Coupon disabled.');
      await _load();
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showCouponReport(Map<String, dynamic> coupon) async {
    final String id = _id(coupon);
    if (id.isEmpty || _saving) return;
    final DateTime to = DateTime.now();
    final DateTime from = to.subtract(const Duration(days: 30));
    setState(() => _saving = true);
    try {
      final DioApiResponse response = await _repository.marketingCouponReport(id, from: from, to: to);
      if (response.errorType != NetErrorType.none) {
        throw StateError(_body(response)['message']?.toString() ?? 'Coupon report could not be loaded.');
      }
      final Map<String, dynamic> report = _map(_body(response)['report']);
      if (!mounted) return;
      final Map<String, dynamic> summary = _map(report['summary']);
      final Map<String, dynamic> settlement = _map(report['settlementImpact']);
      final Map<String, dynamic> couponInfo = _map(report['coupon']);
      final List<Map<String, dynamic>> daily = _rows(report['daily']);
      final int redeemed = int.tryParse(summary['redemptions']?.toString() ?? '') ?? 0;
      final int reserved = int.tryParse(summary['reservedCount']?.toString() ?? '') ?? 0;
      final int released = int.tryParse(summary['releasedCount']?.toString() ?? '') ?? 0;
      final int cancelledAfterRedemption = int.tryParse(summary['cancelledAfterRedemptionCount']?.toString() ?? '') ?? 0;
      final String discount = '₹${(double.tryParse(summary['discountAmount']?.toString() ?? '') ?? 0).toStringAsFixed(2)}';
      final String average = '₹${(double.tryParse(summary['averageDiscount']?.toString() ?? '') ?? 0).toStringAsFixed(2)}';
      final String grossSales = '₹${(double.tryParse(settlement['grossItemSales']?.toString() ?? '') ?? 0).toStringAsFixed(2)}';
      final String netSales = '₹${(double.tryParse(settlement['netItemSalesAfterCoupon']?.toString() ?? '') ?? 0).toStringAsFixed(2)}';
      final String settlementDiscount = '₹${(double.tryParse(settlement['couponDiscount']?.toString() ?? '') ?? 0).toStringAsFixed(2)}';
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (BuildContext context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
              child: ListView(children: <Widget>[
                Text('${couponInfo['code'] ?? ''} · Coupon report', style: Theme.of(context).textTheme.titleLarge),
                Text('Last 30 days · ${report['period'] is Map ? (report['period'] as Map)['timezone'] ?? 'Asia/Kolkata' : 'Asia/Kolkata'}'),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                  _reportMetric(context, 'Redeemed', '$redeemed'),
                  _reportMetric(context, 'Discount applied', discount),
                  _reportMetric(context, 'Average discount', average),
                  _reportMetric(context, 'Reserved now', '$reserved'),
                  _reportMetric(context, 'Released in period', '$released'),
                  _reportMetric(context, 'Cancelled after redeem', '$cancelledAfterRedemption'),
                ]),
                const SizedBox(height: 18),
                Text('Settlement eligible sales', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(settlement['basis']?.toString() ?? 'Delivered and paid Dairy orders.'),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                  _reportMetric(context, 'Delivered and paid orders', '${settlement['orders'] ?? 0}'),
                  _reportMetric(context, 'Gross item sales', grossSales),
                  _reportMetric(context, 'Coupon discount', settlementDiscount),
                  _reportMetric(context, 'Sales after coupon', netSales),
                ]),
                const SizedBox(height: 6),
                Text(settlement['note']?.toString() ?? 'Sales after coupon, before fees and settlement adjustments.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                Text('Daily redemptions', style: Theme.of(context).textTheme.titleMedium),
                if (daily.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 12), child: Text('No completed coupon redemptions in this period.'))
                else ...daily.map((Map<String, dynamic> row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row['date']?.toString() ?? ''),
                  subtitle: Text('${row['redemptions'] ?? 0} redemptions'),
                  trailing: Text('₹${(double.tryParse(row['discountAmount']?.toString() ?? '') ?? 0).toStringAsFixed(2)}'),
                )),
              ]),
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _reportMetric(BuildContext context, String label, String value) => Container(
    constraints: const BoxConstraints(minWidth: 125),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );

  Future<void> _payCampaign(String campaignId) async {
    setState(() => _saving = true);
    try {
      final DioApiResponse init = await _repository.payMarketingCampaign(campaignId);
      if (init.errorType != NetErrorType.none) throw StateError(_body(init)['message']?.toString() ?? 'Could not start payment.');
      final String payLink = _body(init)['payLink']?.toString() ?? '';
      if (payLink.isEmpty) throw StateError('Payment link was not returned.');
      final DioApiResponse orderResponse = await _repository.marketingPaymentOrder(payLink);
      if (orderResponse.errorType != NetErrorType.none) throw StateError(_body(orderResponse)['message']?.toString() ?? 'Payment gateway is unavailable.');
      final Map<String, dynamic> order = _body(orderResponse);
      if (order['success'] != true || order['key'] == null || order['order_id'] == null) throw StateError('Payment gateway is unavailable.');
      _razorpay.open(<String, dynamic>{
        'key': order['key'], 'amount': order['amount'], 'order_id': order['order_id'],
        'name': order['name'] ?? 'LocalWala Dairy promotion',
        'description': 'Dairy sponsored placement', 'prefill': order['prefill'] ?? <String, dynamic>{},
      }, onSuccess: (String? paymentId, String? orderId, String? signature) async {
        if (!mounted) return;
        if (paymentId == null || orderId == null || signature == null) {
          _message('Payment confirmation was incomplete. Refresh campaign status.'); return;
        }
        final DioApiResponse verified = await _repository.verifyMarketingPayment(payLink,
          paymentId: paymentId, orderId: orderId, signature: signature);
        if (!mounted) return;
        _message(verified.errorType == NetErrorType.none && _body(verified)['success'] == true
          ? 'Payment verified. The campaign will run at its scheduled time.'
          : (_body(verified)['message']?.toString() ?? 'Payment is being verified. Refresh shortly.'));
        await _load();
      }, onFailure: (String message) { _message(message); });
    } catch (error) { _message(error.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Marketing & promotions')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marketing & promotions')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }
    final Map<String, dynamic>? package = _selectedPackage;
    final String targeting = package?['targetingLevel']?.toString() ?? '';
    final String placement = package?['placement']?.toString() ?? '';
    final Map<String, dynamic> zone = _map(_coverage['eligibleZone']);
    return Scaffold(
      appBar: AppBar(title: const Text('Marketing & promotions')),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Book a sponsored placement', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6), const Text('Campaigns are reviewed by the platform before payment and publication.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _packageId, decoration: const InputDecoration(labelText: 'Placement package', border: OutlineInputBorder()),
              items: _packages.map((Map<String, dynamic> row) => DropdownMenuItem<String>(value: _id(row),
                child: Text('${row['name']} · ₹${row['price']} · ${row['durationHours']}h'))).toList(),
              onChanged: _saving ? null : (String? value) => setState(() {
                _packageId = value; _selectedLocalities.clear(); _productId = null;
                final Map<String, dynamic> next = _packageById(value);
                if (next['targetingLevel'] == 'city') _selectedLocalities.addAll(_localities.map(_id));
                if (next['targetingLevel'] == 'locality' && _localities.length == 1) _selectedLocalities.add(_id(_localities.first));
              })),
            const SizedBox(height: 12),
            TextField(maxLength: 100, decoration: const InputDecoration(labelText: 'Campaign caption', border: OutlineInputBorder()), onChanged: (String value) => _caption = value),
            if (placement == 'featured_product') ...<Widget>[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(initialValue: _productId, decoration: const InputDecoration(labelText: 'Product to feature', border: OutlineInputBorder()),
                items: _products.map((Map<String, dynamic> row) => DropdownMenuItem<String>(value: _id(row), child: Text(row['name']?.toString() ?? 'Product'))).toList(),
                onChanged: (String? value) => setState(() => _productId = value)),
            ],
            if (targeting == 'zone') ...<Widget>[const SizedBox(height: 12), InputDecorator(
              decoration: const InputDecoration(labelText: 'Published delivery zone', border: OutlineInputBorder()), child: Text(zone['name']?.toString() ?? 'No published zone'))],
            const SizedBox(height: 12), Text('Approved delivery localities${targeting == 'locality' ? ' · choose one' : ''}', style: Theme.of(context).textTheme.titleSmall),
            if (_localities.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No approved delivery localities are available.'))
            else ..._localities.map((Map<String, dynamic> row) {
              final String id = _id(row);
              return CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true, value: _selectedLocalities.contains(id),
                title: Text(row['name']?.toString() ?? 'Locality'),
                onChanged: (targeting == 'city' || _saving) ? null : (bool? checked) => setState(() {
                  if (targeting == 'locality') _selectedLocalities.clear();
                  if (checked == true) {
                    _selectedLocalities.add(id);
                  } else {
                    _selectedLocalities.remove(id);
                  }
                }));
            }),
            const SizedBox(height: 8), OutlinedButton.icon(onPressed: _saving ? null : _chooseStart,
              icon: const Icon(Icons.schedule), label: Text('Starts ${MaterialLocalizations.of(context).formatShortDate(_startsAt)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt))}')),
            const SizedBox(height: 8), FilledButton.icon(onPressed: _saving || _packages.isEmpty ? null : _createCampaign,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.campaign_outlined),
              label: const Text('Submit for review')),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Create a Dairy coupon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Every coupon is reviewed by the platform before customers can redeem it.'),
            const SizedBox(height: 12),
            TextField(maxLength: 40, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Coupon code', border: OutlineInputBorder()), onChanged: (String value) => _couponCode = value),
            TextField(maxLength: 100, decoration: const InputDecoration(labelText: 'Offer title', border: OutlineInputBorder()), onChanged: (String value) => _couponTitle = value),
            TextField(maxLength: 500, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()), onChanged: (String value) => _couponDescription = value),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(initialValue: _couponType, decoration: const InputDecoration(labelText: 'Discount type', border: OutlineInputBorder()),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'fixed', child: Text('Fixed amount (₹)')),
                DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
              ],
              onChanged: _saving ? null : (String? value) => setState(() => _couponType = value ?? 'fixed')),
            const SizedBox(height: 8),
            TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _couponType == 'percentage' ? 'Discount (%)' : 'Discount (₹)', border: const OutlineInputBorder()), onChanged: (String value) => _couponValue = value),
            if (_couponType == 'percentage') ...<Widget>[
              const SizedBox(height: 8),
              TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Maximum savings (₹)', border: OutlineInputBorder()), onChanged: (String value) => _couponMaxDiscount = value),
            ],
            const SizedBox(height: 8),
            TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Minimum order (₹)', border: OutlineInputBorder()), onChanged: (String value) => _couponMinimum = value),
            const SizedBox(height: 8),
            TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maximum redemptions (optional)', border: OutlineInputBorder()), onChanged: (String value) => _couponMaxRedemptions = value),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _saving ? null : _chooseCouponEnd, icon: const Icon(Icons.event_outlined), label: Text('Valid through ${MaterialLocalizations.of(context).formatShortDate(_couponEndsAt)}')),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _saving ? null : _createCoupon, icon: const Icon(Icons.sell_outlined), label: const Text('Submit coupon for review')),
          ]))),
          const SizedBox(height: 20), Text('Your coupons', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
          if (_coupons.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No coupons yet.'))),
          ..._coupons.map((Map<String, dynamic> coupon) => Card(child: ListTile(
            onTap: _saving ? null : () => _showCouponReport(coupon),
            title: Text('${coupon['code'] ?? ''} · ${coupon['title'] ?? 'Dairy coupon'}'),
            subtitle: Text('${coupon['discountType'] == 'percentage' ? '${coupon['discountValue']}% off' : '₹${coupon['discountValue']} off'} · ${coupon['status'] ?? 'pending_review'} · ${coupon['redeemedCount'] ?? 0} redeemed'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              IconButton(tooltip: 'View redemption report', onPressed: _saving ? null : () => _showCouponReport(coupon), icon: const Icon(Icons.analytics_outlined)),
              if (coupon['status'] == 'active' || coupon['status'] == 'pending_review')
                IconButton(tooltip: 'Disable coupon', onPressed: _saving ? null : () => _disableCoupon(coupon), icon: const Icon(Icons.pause_circle_outline)),
            ]),
          ))),
          const SizedBox(height: 20), Text('Your campaigns', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
          if (_campaigns.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No promotion campaigns yet.'))),
          ..._campaigns.map((Map<String, dynamic> campaign) {
            final Map<String, dynamic> snapshot = _map(campaign['packageSnapshot']);
            final Map<String, dynamic> metrics = _map(campaign['metrics']);
            final String status = campaign['status']?.toString() ?? 'pending';
            final String payment = campaign['paymentStatus']?.toString() ?? 'unpaid';
            return Card(child: ListTile(title: Text(campaign['caption']?.toString() ?? snapshot['name']?.toString() ?? 'Dairy campaign'),
              subtitle: Text('${snapshot['name'] ?? 'Placement'} · $status · payment: $payment\n${metrics['impressions'] ?? 0} views · ${metrics['clicks'] ?? 0} clicks'),
              isThreeLine: true, trailing: status == 'approved_unpaid'
                ? TextButton(onPressed: _saving ? null : () => _payCampaign(_id(campaign)), child: const Text('Pay'))
                : const Icon(Icons.chevron_right)));
          }),
        ])),
    );
  }
}
