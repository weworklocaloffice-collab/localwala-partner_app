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
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Read-only view of the admin-owned service variant catalogue, matched with
/// this provider's offering price. Create or edit prices from Catalogue.
class VariantsScreen extends StatefulWidget {
  const VariantsScreen({super.key});

  @override
  State<VariantsScreen> createState() => _VariantsScreenState();
}

class _VariantsScreenState extends State<VariantsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  bool _loadingVariants = false;
  String? _error;
  String? _serviceId;
  List<LsCatalogueService> _services = const <LsCatalogueService>[];
  List<LsCatalogueVariant> _variants = const <LsCatalogueVariant>[];
  List<LsOffering> _offerings = const <LsOffering>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DioApiResponse> responses = await Future.wait(
        <Future<DioApiResponse>>[
          _repository.offerings(),
          _repository.publicServices(),
        ],
      );
      _ensureOk(responses[0]);
      _ensureOk(responses[1]);
      final List<dynamic> offeringRows =
          (decodeBody(responses[0])['results'] ?? <dynamic>[]) as List<dynamic>;
      final List<dynamic> serviceRows =
          (decodeBody(responses[1])['results'] ?? <dynamic>[]) as List<dynamic>;
      final List<LsCatalogueService> services = serviceRows
          .whereType<Map<String, dynamic>>()
          .map(LsCatalogueService.fromJson)
          .toList();
      final bool selectedExists = services.any(
        (LsCatalogueService s) => s.id == _serviceId,
      );
      setState(() {
        _services = services;
        _offerings = offeringRows
            .whereType<Map<String, dynamic>>()
            .map(LsOffering.fromJson)
            .toList();
        if (!selectedExists) {
          _serviceId = null;
          _variants = const <LsCatalogueVariant>[];
        }
        _loading = false;
      });
      if (_serviceId != null) await _loadVariants(_serviceId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadVariants(String serviceId) async {
    setState(() {
      _loadingVariants = true;
      _variants = const <LsCatalogueVariant>[];
    });
    try {
      final DioApiResponse response = await _repository.publicServiceDetail(
        serviceId,
      );
      _ensureOk(response);
      final List<dynamic> raw =
          (decodeBody(response)['variants'] ?? <dynamic>[]) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _variants = raw
            .whereType<Map<String, dynamic>>()
            .map(LsCatalogueVariant.fromJson)
            .toList();
        _loadingVariants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVariants = false;
        _error = '$e';
      });
    }
  }

  void _selectService(String? id) {
    setState(() {
      _serviceId = id;
      _variants = const <LsCatalogueVariant>[];
    });
    if (id != null) _loadVariants(id);
  }

  LsOffering? _offeringFor(String variantId) {
    for (final LsOffering offering in _offerings) {
      if (offering.serviceId == _serviceId && offering.variantId == variantId) {
        return offering;
      }
    }
    return null;
  }

  void _ensureOk(DioApiResponse response) {
    final int? status = response.statusCode;
    if (status == null || status >= 400) {
      final dynamic message = decodeBody(response)['message'];
      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : 'Request failed${status == null ? '' : ' ($status)'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)?.ls_variant_catalogue ?? 'Variant catalogue',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.ls_variants_localwala_note ?? 'Variants are set by LocalWala. Publish your price from Catalogue.',
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.ls_service ?? 'Service',
              border: const OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _serviceId,
                isExpanded: true,
                hint: Text(AppLocalizations.of(context)?.ls_choose_service ?? 'Choose a service'),
                items: _services
                    .map(
                      (LsCatalogueService service) => DropdownMenuItem<String>(
                        value: service.id,
                        child: Text(
                          service.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _selectService,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading || _loadingVariants)
            const Center(child: CircularProgressIndicator())
            else if (_error != null)
            Expanded(child: LsErrorState(message: _error!, onRetry: _load))
          else if (_serviceId == null)
            Expanded(
              child: LsEmptyState(
                icon: Icons.format_list_bulleted_outlined,
                title: AppLocalizations.of(context)?.ls_choose_service_to_see_variants ?? 'Choose a service',
                subtitle: 'Select a service above to view its variants.',
              ),
            )
          else if (_variants.isEmpty)
            Expanded(
              child: LsEmptyState(
                icon: Icons.format_list_bulleted_outlined,
                title: AppLocalizations.of(context)?.ls_no_variants ?? 'No variants',
                subtitle: 'This service has no variants.',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _variants.length,
                itemBuilder: (BuildContext context, int i) {
                  final LsCatalogueVariant variant = _variants[i];
                  final LsOffering? offering = _offeringFor(variant.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(variant.name),
                      subtitle: Text(
                        '${variant.durationMinutes} min · catalogue ₹${variant.basePrice}',
                      ),
                      trailing: Text(
                        offering == null
                            ? (AppLocalizations.of(context)?.ls_not_offered ?? 'Not offered')
                            : '₹${offering.price} · ${offering.status}',
                        style: TextStyle(
                          color: offering?.status == 'active'
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
