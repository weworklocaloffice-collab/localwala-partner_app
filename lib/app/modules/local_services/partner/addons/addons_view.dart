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
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Read-only view of the admin-owned add-on catalogue for a service.
/// Add-ons are priced centrally and selected by the customer at booking.
class AddonsScreen extends StatefulWidget {
  const AddonsScreen({super.key});

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  bool _loadingAddons = false;
  String? _error;
  String? _serviceId;
  List<LsCatalogueService> _services = const <LsCatalogueService>[];
  List<LsCatalogueAddon> _addons = const <LsCatalogueAddon>[];

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
      final DioApiResponse response = await _repository.publicServices();
      _ensureOk(response);
      final List<dynamic> raw =
          (decodeBody(response)['results'] ?? <dynamic>[]) as List<dynamic>;
      final List<LsCatalogueService> services = raw
          .whereType<Map<String, dynamic>>()
          .map(LsCatalogueService.fromJson)
          .toList();
      final bool selectedExists = services.any(
        (LsCatalogueService s) => s.id == _serviceId,
      );
      setState(() {
        _services = services;
        if (!selectedExists) {
          _serviceId = null;
          _addons = const <LsCatalogueAddon>[];
        }
        _loading = false;
      });
      if (_serviceId != null) await _loadAddons(_serviceId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadAddons(String serviceId) async {
    setState(() {
      _loadingAddons = true;
      _addons = const <LsCatalogueAddon>[];
    });
    try {
      final DioApiResponse response = await _repository.publicServiceDetail(
        serviceId,
      );
      _ensureOk(response);
      final List<dynamic> raw =
          (decodeBody(response)['addons'] ?? <dynamic>[]) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _addons = raw
            .whereType<Map<String, dynamic>>()
            .map(LsCatalogueAddon.fromJson)
            .toList();
        _loadingAddons = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAddons = false;
        _error = '$e';
      });
    }
  }

  void _selectService(String? id) {
    setState(() {
      _serviceId = id;
      _addons = const <LsCatalogueAddon>[];
    });
    if (id != null) _loadAddons(id);
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
            AppLocalizations.of(context)?.ls_addon_catalogue ?? 'Add-on catalogue',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.ls_addon_catalogue_note ?? 'Add-ons are set by LocalWala and selected by customers at booking.',
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
          if (_loading || _loadingAddons)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry')),
                  ],
                ),
              ),
            )
          else if (_serviceId == null)
            Expanded(
              child: Center(child: Text(AppLocalizations.of(context)?.ls_choose_service_to_see_addons ?? 'Choose a service to see add-ons')),
            )
          else if (_addons.isEmpty)
            Expanded(
              child: Center(child: Text(AppLocalizations.of(context)?.ls_no_addons ?? 'This service has no add-ons')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _addons.length,
                itemBuilder: (BuildContext context, int i) {
                  final LsCatalogueAddon addon = _addons[i];
                  return ListTile(
                    title: Text(addon.name),
                    subtitle: Text(addon.unit),
                    trailing: Text('₹${addon.price}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
