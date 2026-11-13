/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
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
import 'package:partner/app/modules/jhatka/partner/catalogue/jhatka_catalogue_repository.dart';
import 'package:partner/app/modules/jhatka/partner/subscriptions/jhatka_subscriptions_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Subscribe a customer on behalf of the outlet.
///
/// ## The customer is picked, never typed
///
/// `customerId` comes from search results only. A mistyped id subscribes a
/// stranger, and there is no undo that un-charges them — so the field is a
/// picker, not a text box. Search is scoped server-side to this outlet's own
/// customers.
///
/// ## Only subscribable variants are offered
///
/// Eggs and whole fish carry `subscriptionEligible: false` (nobody subscribes
/// to eggs; fish cannot sit overnight). The server refuses them with a reason,
/// but offering them and then refusing is showing a button that lies — so the
/// picker filters client-side on the flag the catalogue now exposes.
class SubscriptionCreateScreen extends StatefulWidget {
  const SubscriptionCreateScreen({super.key});

  @override
  State<SubscriptionCreateScreen> createState() =>
      _SubscriptionCreateScreenState();
}

class _SubscriptionCreateScreenState extends State<SubscriptionCreateScreen> {
  final JhatkaSubscriptionsRepository _subscriptions =
      JhatkaSubscriptionsRepository();
  final JhatkaCatalogueRepository _catalogue = JhatkaCatalogueRepository();

  final TextEditingController _search = TextEditingController();

  bool _searching = false;
  bool _loadingVariants = true;
  bool _submitting = false;
  List<dynamic> _customers = const <dynamic>[];
  String? _customerId;
  String _customerLabel = '';
  List<dynamic> _variants = const <dynamic>[];
  // variant id → quantity in the variant's own unit.
  final Map<String, TextEditingController> _quantities =
      <String, TextEditingController>{};
  final Set<String> _picked = <String>{};

  String _scheduleType = 'weekly';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  static const List<String> _schedules = <String>[
    'daily',
    'alternate_days',
    'weekly',
    'custom_days',
  ];

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  @override
  void dispose() {
    _search.dispose();
    for (final TextEditingController c in _quantities.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVariants() async {
    setState(() => _loadingVariants = true);
    final DioApiResponse response = await _catalogue.products();
    if (!mounted) return;
    setState(() => _loadingVariants = false);
    if (response.errorType != NetErrorType.none) return;
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> products =
        (body['products'] as List?) ?? const <dynamic>[];
    final List<dynamic> eligible = <dynamic>[];
    for (final dynamic rawProduct in products) {
      final Map<String, dynamic> product = Map<String, dynamic>.from(
        rawProduct as Map,
      );
      for (final dynamic rawVariant
          in (product['variants'] as List?) ?? const <dynamic>[]) {
        final Map<String, dynamic> variant = Map<String, dynamic>.from(
          rawVariant as Map,
        );
        if (variant['subscriptionEligible'] == true) {
          eligible.add(<String, dynamic>{
            ...variant,
            'productName': product['name'] ?? '',
          });
        }
      }
    }
    setState(() {
      _variants = eligible;
      for (final dynamic raw in eligible) {
        final Map<String, dynamic> v = Map<String, dynamic>.from(raw as Map);
        final String id = (v['id'] ?? v['_id'] ?? '').toString();
        _quantities[id] = TextEditingController(text: '1');
      }
    });
  }

  Future<void> _doSearch() async {
    final String q = _search.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaTypeTwoChars),
        ),
      );
      return;
    }
    setState(() {
      _searching = true;
      _customers = const <dynamic>[];
    });
    final DioApiResponse response = await _subscriptions.searchCustomers(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaSearchFailed),
        ),
      );
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _customers = (body['customers'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _startDate = date);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_customerId == null || _customerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaPickCustomerFirst),
        ),
      );
      return;
    }
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final dynamic raw in _variants) {
      final Map<String, dynamic> v = Map<String, dynamic>.from(raw as Map);
      final String id = (v['id'] ?? v['_id'] ?? '').toString();
      if (!_picked.contains(id)) continue;
      final double? qty = double.tryParse((_quantities[id]?.text ?? '').trim());
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity for ${v['name'] ?? id} must be positive.'),
          ),
        );
        return;
      }
      items.add(<String, dynamic>{
        'variant': id,
        'quantity': <String, dynamic>{'value': qty, 'unit': 'KG'},
      });
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaPickAtLeastOneVariant,
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final DioApiResponse response = await _subscriptions.create(
      customerId: _customerId!,
      items: items,
      scheduleType: _scheduleType,
      startDate: _iso(_startDate),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.errorType != NetErrorType.none) {
      String message = 'Create failed. Retry.';
      try {
        message = (decodeBody(response)['message'] ?? message).toString();
      } catch (_) {
        message = 'Create failed. Retry.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.jhatkaActionNewSubscription),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Customer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldNameOrPhone,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppLocalizations.of(context)!.jhatkaActionSearch,
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                onPressed: _searching ? null : _doSearch,
              ),
            ],
          ),
          if (_customerLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(
                  AppLocalizations.of(context)!.jhatkaForLabel(_customerLabel),
                ),
              ),
            ),
          ..._customers.map((dynamic raw) {
            final Map<String, dynamic> c = Map<String, dynamic>.from(
              raw as Map,
            );
            final String id = (c['id'] ?? '').toString();
            return ListTile(
              title: Text((c['name'] ?? '—').toString()),
              subtitle: Text((c['phone'] ?? '').toString()),
              trailing: _customerId == id
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => setState(() {
                _customerId = id;
                _customerLabel =
                    '${c['name'] ?? ''} ${(c['phone'] ?? '').toString()}'
                        .trim();
              }),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Variants (subscribable only)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_loadingVariants)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_variants.isEmpty)
            Text(AppLocalizations.of(context)!.jhatkaNoSubscribableVariants),
          ..._variants.map((dynamic raw) {
            final Map<String, dynamic> v = Map<String, dynamic>.from(
              raw as Map,
            );
            final String id = (v['id'] ?? v['_id'] ?? '').toString();
            final bool picked = _picked.contains(id);
            return Card(
              child: CheckboxListTile(
                title: Text(
                  '${v['productName'] ?? ''} · ${v['name'] ?? v['sku'] ?? ''}',
                ),
                subtitle: Text('${v['priceSale'] ?? v['priceMrp'] ?? ''}'),
                value: picked,
                onChanged: (bool? on) {
                  setState(() {
                    if (on == true) {
                      _picked.add(id);
                    } else {
                      _picked.remove(id);
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            initialValue: _scheduleType,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.jhatkaFieldRepeats,
              border: OutlineInputBorder(),
            ),
            items: _schedules
                .map(
                  (String s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)),
                )
                .toList(),
            onChanged: (String? v) {
              if (v != null) setState(() => _scheduleType = v);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(AppLocalizations.of(context)!.jhatkaFieldStarts),
            subtitle: Text(_iso(_startDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create subscription',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
