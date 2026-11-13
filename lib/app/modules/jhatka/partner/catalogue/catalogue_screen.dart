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

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/jhatka/partner/catalogue/jhatka_catalogue_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Catalogue browse plus outlet price overrides.
///
/// Products and variants are read-only here — taxonomy is admin-owned. What
/// the outlet CAN do is price: draft an override with a reason and a closed
/// date range, and (owner/manager) approve or revoke. Drafts beyond ±20%
/// need a *different* approver than the creator; the row says so itself.
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final JhatkaCatalogueRepository _repository = JhatkaCatalogueRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _products = const <dynamic>[];
  List<dynamic> _overrides = const <dynamic>[];
  String? _actingOn;

  final TextEditingController _price = TextEditingController();
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  String? _variantId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _price.dispose();
    _from.dispose();
    _to.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final List<DioApiResponse> results = await Future.wait(
      <Future<DioApiResponse>>[_repository.products(), _repository.overrides()],
    );
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load catalogue.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _products =
          (decodeBody(results[0])['products'] as List?) ?? const <dynamic>[];
      _overrides =
          (decodeBody(results[1])['overrides'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _act(String key, Future<DioApiResponse> Function() call) async {
    setState(() => _actingOn = key);
    final DioApiResponse response = await call();
    if (!mounted) return;
    setState(() => _actingOn = null);
    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaDidNotGoThrough),
        ),
      );
    }
  }

  List<Map<String, String>> _variantOptions() {
    final List<Map<String, String>> options = <Map<String, String>>[];
    for (final dynamic rawProduct in _products) {
      final Map<String, dynamic> product = Map<String, dynamic>.from(
        rawProduct as Map,
      );
      final List<dynamic> variants =
          (product['variants'] as List?) ?? const <dynamic>[];
      for (final dynamic rawVariant in variants) {
        final Map<String, dynamic> variant = Map<String, dynamic>.from(
          rawVariant as Map,
        );
        options.add(<String, String>{
          'id': (variant['id'] ?? variant['_id'] ?? '').toString(),
          'label':
              '${product['name'] ?? ''} · ${(variant['name'] ?? variant['sku'] ?? '').toString()}',
        });
      }
    }
    return options;
  }

  Future<void> _createSheet() async {
    final List<Map<String, String>> options = _variantOptions();
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaNoVariantsToPrice),
        ),
      );
      return;
    }
    String? picked = _variantId;
    final bool? go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'New price override',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: picked,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldVariant,
                      border: OutlineInputBorder(),
                    ),
                    items: options
                        .map(
                          (Map<String, String> o) => DropdownMenuItem<String>(
                            value: o['id'],
                            child: Text(
                              o['label'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) {
                      setSheet(() => picked = v);
                      setState(() => _variantId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 22),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldPricePerUnit,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _from,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldFromDate,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _to,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldToDate,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reason,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldReasonMin10,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        AppLocalizations.of(context)!.jhatkaDraftOverride,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (go != true || !mounted) return;
    final double? price = double.tryParse(_price.text.trim());
    if (_variantId == null || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaPickVariantAndPrice,
          ),
        ),
      );
      return;
    }
    await _act(
      'create',
      () => _repository.createOverride(
        variant: _variantId!,
        pricePerUnit: price,
        effectiveFrom: _from.text.trim(),
        effectiveTo: _to.text.trim(),
        reason: _reason.text.trim(),
      ),
    );
  }

  Future<void> _revokeSheet(String overrideId) async {
    final TextEditingController reason = TextEditingController();
    final bool? go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Revoke override',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.storesFieldReasonRequired,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionRevoke),
                ),
              ),
            ],
          ),
        );
      },
    );
    final String text = reason.text.trim();
    reason.dispose();
    if (go != true || text.isEmpty || !mounted) return;
    await _act(
      'revoke:$overrideId',
      () => _repository.revokeOverride(overrideId, text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavCataloguePrices,
      icon: Icons.storefront_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaCatalogueUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _sectionTitle('Price overrides (${_overrides.length})'),
          ..._overrides.map(_overrideTile),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _actingOn != null ? null : _createSheet,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionNewOverride,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Products (${_products.length})'),
          ..._products.map(_productTile),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _overrideTile(dynamic raw) {
    final Map<String, dynamic> override = Map<String, dynamic>.from(raw as Map);
    final String id = (override['id'] ?? override['_id'] ?? '').toString();
    final String status = (override['status'] ?? '').toString();
    final bool busy = _actingOn != null && _actingOn!.endsWith(id);
    final num variance = (override['variancePct'] as num?) ?? 0;
    final bool needsSecond =
        (override['requiresSecondApproval'] as bool?) ?? false;
    final Map<String, dynamic>? variant = override['variant'] is Map
        ? Map<String, dynamic>.from(override['variant'] as Map)
        : null;
    return Card(
      child: ExpansionTile(
        title: Text(
          '${variant?['name'] ?? variant?['sku'] ?? 'Variant'} · '
          '${override['pricePerUnit'] ?? '—'}',
        ),
        subtitle: Text(
          '$status · ${variance >= 0 ? '+' : ''}$variance% vs list'
          '${needsSecond ? ' · needs a different approver' : ''}',
        ),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : StatusChip(
                label: status.isEmpty ? '—' : status,
                color: status == 'active'
                    ? AppColors.canInStore
                    : AppColors.grey,
              ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (status == 'draft')
                  OutlinedButton(
                    onPressed: () => _act(
                      'approve:$id',
                      () => _repository.approveOverride(id),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionApproveActivate,
                    ),
                  ),
                if (status == 'active')
                  OutlinedButton(
                    onPressed: () => _revokeSheet(id),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionRevoke,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productTile(dynamic raw) {
    final Map<String, dynamic> product = Map<String, dynamic>.from(raw as Map);
    final List<dynamic> variants =
        (product['variants'] as List?) ?? const <dynamic>[];
    return Card(
      child: ExpansionTile(
        title: Text((product['name'] ?? '—').toString()),
        subtitle: Text(
          AppLocalizations.of(context)!.jhatkaVariantCount(variants.length),
        ),
        children: variants.map((dynamic rawVariant) {
          final Map<String, dynamic> variant = Map<String, dynamic>.from(
            rawVariant as Map,
          );
          return ListTile(
            dense: true,
            title: Text('${variant['name'] ?? variant['sku'] ?? '—'}'),
            subtitle: Text(
              '${variant['pricePerUnit'] ?? variant['priceSale'] ?? '—'} '
              '${variant['priceBasis'] ?? ''} · '
              '${variant['measurementMode'] ?? ''}',
            ),
          );
        }).toList(),
      ),
    );
  }
}
