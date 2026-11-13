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
import 'package:partner/app/modules/jhatka/partner/driver/jhatka_rider_repository.dart';
import 'package:partner/app/modules/jhatka/partner/driver/rider_delivery_screen.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The rider's queue: only their outlet's deliveries, newest first.
///
/// A rider never sends an outlet id — the server resolves it from the rider
/// record — and a mismatched request is OUT_OF_SCOPE, not an empty list.
class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  final JhatkaRiderRepository _repository = JhatkaRiderRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _deliveries = const <dynamic>[];

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
    final DioApiResponse response = await _repository.deliveries();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load deliveries.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _deliveries = (body['deliveries'] as List?) ?? const <dynamic>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavMyDeliveries,
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
            title: AppLocalizations.of(context)!.jhatkaDeliveriesUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_deliveries.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaNothingAssigned,
            message: 'New dispatches from your outlet appear here.',
            icon: Icons.delivery_dining_outlined,
          )
        else
          Card(
            child: Column(
              children: _deliveries.map((dynamic raw) {
                final Map<String, dynamic> delivery = Map<String, dynamic>.from(
                  raw as Map,
                );
                final String id = (delivery['id'] ?? delivery['_id'] ?? '')
                    .toString();
                final String status = (delivery['status'] ?? '').toString();
                final Map<String, dynamic>? order = delivery['order'] is Map
                    ? Map<String, dynamic>.from(delivery['order'] as Map)
                    : null;
                return ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.jhatkaDeliveryNo(
                      (delivery['deliveryNo'] ?? '—').toString(),
                    ),
                  ),
                  subtitle: Text(
                    '$status'
                    '${order != null ? ' · order ${order['orderNo'] ?? ''}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      StatusChip(
                        label: status.isEmpty ? '—' : status,
                        color: status == 'failed'
                            ? AppColors.expired
                            : status == 'delivered'
                            ? AppColors.canInStore
                            : AppColors.grey,
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RiderDeliveryScreen(deliveryId: id),
                      ),
                    );
                    if (mounted) await _load();
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
