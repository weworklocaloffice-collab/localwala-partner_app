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
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/jhatka/jhatka_endpoints.dart'
    as jhatka_endpoints;
import 'package:partner/app/modules/jhatka/partner/fulfilment/fulfilment_screen.dart';
import 'package:partner/app/modules/jhatka/partner/intake/intake_screen.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/weigh_screen.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Orders awaiting the counter. Tap one to open the weighing screen.
///
/// Backed by `GET /jhatka/partner/orders`. Weighing itself is offered only
/// for lines in a weighable lifecycle; the server refuses the rest, so rows
/// that cannot move forward show no action.
class JhatkaOrderListScreen extends StatefulWidget {
  const JhatkaOrderListScreen({super.key});

  @override
  State<JhatkaOrderListScreen> createState() => _JhatkaOrderListScreenState();
}

class _JhatkaOrderListScreenState extends State<JhatkaOrderListScreen> {
  final AuthRepository _auth = AuthRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _orders = const <dynamic>[];

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
    final DioApiResponse response = await ApiRequestService.makeRequest(
      jhatka_endpoints.JhatkaPartnerEndpoints.orderList,
      method: 'GET',
      token: await _auth.authToken(),
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load orders.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _orders = (body['orders'] as List?) ?? const <dynamic>[];
    });
  }

  static const Set<String> _weighable = <String>{
    'PREPARING',
    'WEIGHING',
    'WEIGHT_CONFIRMED',
  };

  static const Set<String> _fulfillable = <String>{
    'WEIGHT_CONFIRMED',
    'PACKING',
    'READY',
  };

  /// Orders waiting on the counter: receive → accept → prepare, or reject.
  /// Without these the rows below are dead — weighing needs PREPARING and
  /// nothing in between existed.
  static const Set<String> _intake = <String>{
    'CREATED',
    'PAYMENT_PENDING',
    'PAID',
    'OUTLET_RECEIVED',
    'ACCEPTED',
  };

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavOrders,
      icon: Icons.receipt_long_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaOrdersUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_orders.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaNoOrders,
            message: 'Jhatka orders for this outlet appear here.',
            icon: Icons.receipt_long_outlined,
          )
        else
          Card(
            child: Column(
              children: _orders.map((dynamic raw) {
                final Map<String, dynamic> order = Map<String, dynamic>.from(
                  raw as Map,
                );
                final String id = (order['id'] ?? order['_id'] ?? '')
                    .toString();
                final String lifecycle = (order['lifecycle'] ?? '').toString();
                final bool weighable = _weighable.contains(lifecycle);
                final bool fulfillable = _fulfillable.contains(lifecycle);
                final bool intake = _intake.contains(lifecycle);
                return ListTile(
                  title: Text('Order #${order['orderNo'] ?? '—'}'),
                  subtitle: Text(lifecycle.isEmpty ? '—' : lifecycle),
                  trailing: weighable
                      ? const Icon(Icons.scale_outlined)
                      : fulfillable
                      ? const Icon(Icons.local_shipping_outlined)
                      : intake
                      ? const Icon(Icons.inbox_outlined)
                      : null,
                  onTap: weighable
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WeighScreen(orderId: id),
                            ),
                          );
                        }
                      : fulfillable
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FulfilmentScreen(
                                orderId: id,
                                lifecycle: lifecycle,
                                fulfilmentMode:
                                    (order['fulfilmentMode'] ?? 'delivery')
                                        .toString(),
                              ),
                            ),
                          );
                        }
                      : intake
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => IntakeScreen(orderId: id),
                            ),
                          );
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
