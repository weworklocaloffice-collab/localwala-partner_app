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
import 'package:partner/app/modules/jhatka/partner/fulfilment/jhatka_fulfilment_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Fleet and in-flight deliveries: one screen because dispatch is the join.
///
/// Riders move active/inactive/suspended with reasons, never deleted (BR-24:
/// delivery history is a settlement input). Ineligible riders list with the
/// reason rather than vanishing. Deliveries show status, COD state and the
/// POD temperature outcome.
class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final JhatkaFulfilmentRepository _repository = JhatkaFulfilmentRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _drivers = const <dynamic>[];
  List<dynamic> _deliveries = const <dynamic>[];
  String? _actingOn;

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
    final List<DioApiResponse> results = await Future.wait(
      <Future<DioApiResponse>>[
        _repository.outletDrivers(),
        _repository.deliveries(activeOnly: true),
      ],
    );
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load fleet.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _drivers =
          (decodeBody(results[0])['drivers'] as List?) ?? const <dynamic>[];
      _deliveries =
          (decodeBody(results[1])['deliveries'] as List?) ?? const <dynamic>[];
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

  Future<void> _statusSheet(String driverId, String name) async {
    String? picked;
    final TextEditingController reason = TextEditingController();
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
                  Text(
                    'Set $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: picked,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.realEstateCheckoutStatus,
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'active',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaStatusActive,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'inactive',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaStatusInactive,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'suspended',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaStatusSuspended,
                        ),
                      ),
                    ],
                    onChanged: (String? v) => setSheet(() => picked = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reason,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldReasonOptional,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        AppLocalizations.of(context)!.storesActionApply,
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
    final String text = reason.text.trim();
    reason.dispose();
    if (go != true || picked == null || !mounted) return;
    await _act(
      'status:$driverId',
      () => _repository.setDriverStatus(
        driverId: driverId,
        status: picked!,
        reason: text.isEmpty ? null : text,
      ),
    );
  }

  Future<void> _deliverySheet(Map<String, dynamic> delivery) async {
    final String id = (delivery['id'] ?? '').toString();
    final DioApiResponse response = await _repository.deliveryDetail(id);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaCouldNotLoadDelivery,
          ),
        ),
      );
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> detail = Map<String, dynamic>.from(
      (body['delivery'] ?? {}) as Map,
    );
    final dynamic pod = body['pod'];
    if (!mounted) return;
    await showModalBottomSheet<void>(
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
              Text(
                'Delivery ${detail['deliveryNo'] ?? '—'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Status ${(detail['status'] ?? '—').toString()}'),
              Text('COD ${(detail['codStatus'] ?? '—').toString()}'),
              Text(
                'Collect ${detail['codCollectionAmount'] ?? '—'} · '
                'collected ${detail['codCollectedAmount'] ?? '—'}',
              ),
              if (pod is Map) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'POD: delivered at ${(pod['deliveredTempC'] ?? '?').toString()}°C'
                  '${pod['coldChainBreached'] == true ? ' — BREACH, complaint raised' : ''}',
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavFleet,
      icon: Icons.delivery_dining_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaFleetUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _sectionTitle('Riders (${_drivers.length})'),
          ..._drivers.map(_driverTile),
          const SizedBox(height: 12),
          _sectionTitle('In flight (${_deliveries.length})'),
          ..._deliveries.map(_deliveryTile),
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

  Widget _driverTile(dynamic raw) {
    final Map<String, dynamic> driver = Map<String, dynamic>.from(raw as Map);
    final String id = (driver['id'] ?? '').toString();
    final String status = (driver['status'] ?? '').toString();
    final bool eligible = driver['eligible'] == true;
    final bool busy = _actingOn == 'status:$id';
    return Card(
      child: ListTile(
        title: Text((driver['name'] ?? '—').toString()),
        subtitle: Text(
          '$status${eligible ? '' : ' · ${(driver['ineligibleReason'] ?? 'unavailable').toString()}'}',
        ),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StatusChip(
                    label: status.isEmpty ? '—' : status,
                    color: eligible ? AppColors.canInStore : AppColors.grey,
                  ),
                  TextButton(
                    onPressed: () =>
                        _statusSheet(id, (driver['name'] ?? '').toString()),
                    child: Text(AppLocalizations.of(context)!.jhatkaActionSet),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _deliveryTile(dynamic raw) {
    final Map<String, dynamic> delivery = Map<String, dynamic>.from(raw as Map);
    final Map<String, dynamic>? order = delivery['order'] is Map
        ? Map<String, dynamic>.from(delivery['order'] as Map)
        : null;
    return Card(
      child: ListTile(
        title: Text('Delivery ${(delivery['deliveryNo'] ?? '—').toString()}'),
        subtitle: Text(
          '${(delivery['status'] ?? '').toString()} · '
          'COD ${(delivery['codStatus'] ?? '').toString()}'
          '${order != null ? ' · order ${order['orderNo'] ?? ''}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _deliverySheet(delivery),
      ),
    );
  }
}
