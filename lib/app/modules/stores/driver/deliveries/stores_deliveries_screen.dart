/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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

import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// The store driver's delivery list and handover.
///
/// ## BR-29 is why there is no "Mark delivered" button
///
/// The only path to `delivered` is [StoresDriverRepository.verifyOtp], which asks the server
/// to compare the customer's OTP against the hash it stored at assignment. The dialog below
/// collects that code. A driver who cannot complete a handover without the customer reading
/// out a code is the entire point — goods and cash change hands against proof.
///
/// The server also caps attempts (three) and expires the OTP after ten minutes, so this
/// screen surfaces the server's message rather than guessing locally.
class StoresDeliveriesScreen extends StatefulWidget {
  const StoresDeliveriesScreen({super.key});

  @override
  State<StoresDeliveriesScreen> createState() => _StoresDeliveriesScreenState();
}

class _StoresDeliveriesScreenState extends State<StoresDeliveriesScreen> {
  StoresDriverRepository? _repo;

  /// Cached once per load. A bare `repo.deliveries()` inside `build` creates a new Future
  /// on every rebuild, so tapping a status chip would re-hit the API just to redraw.
  Future<Map<String, dynamic>>? _future;
  String? _status;

  static const List<String> _filters = <String>[
    'assigned',
    'accepted',
    'picked_up',
    'out_for_delivery',
    'delivered',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    _repo = StoresDriverRepository();
    _future = _repo!.deliveries();
  }

  void _reload() {
    setState(() {
      _repo = StoresDriverRepository();
      _future = _repo!.deliveries();
    });
  }

  /// Advances the delivery one step along the server's state machine
  /// (`assigned → accepted → picked_up → out_for_delivery`). `delivered` is
  /// deliberately unreachable here: BR-29 requires the customer OTP.
  Future<void> _advance(
    BuildContext context,
    Map<String, dynamic> delivery,
    String next,
  ) async {
    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? id = delivery['_id']?.toString();
    if (id == null) return;

    try {
      await repo.transition(id, next);
      messenger.showSnackBar(
        SnackBar(content: Text('Delivery marked ${next.replaceAll('_', ' ')}')),
      );
      _reload();
    } on StoresApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _verifyOtp(BuildContext context, Map<String, dynamic> delivery) async {
    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? id = delivery['_id']?.toString() ?? delivery['order']?.toString();

    if (id == null) return;

    final TextEditingController otp = TextEditingController();
    final String? submitted = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.storesDialogCustomerHandover),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Ask the customer for the delivery OTP.'),
              const SizedBox(height: 12),
              TextField(
                controller: otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.storesFieldOtp),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.storesActionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(otp.text.trim()),
              child: Text(l10n.storesActionVerify),
            ),
          ],
        );
      },
    );

    otp.dispose();
    if (submitted == null || submitted.isEmpty || !mounted) return;

    try {
      await repo.verifyOtp(id, submitted);
      messenger.showSnackBar(const SnackBar(content: Text('Delivered')));
      _reload();
    } on StoresApiException catch (e) {
      // "Invalid OTP" and "Maximum OTP attempts exceeded" both land here. The driver needs
      // the server's wording, because the next action differs: retry vs call the outlet.
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _fail(BuildContext context, Map<String, dynamic> delivery) async {
    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? id = delivery['_id']?.toString();
    if (id == null) return;

    final TextEditingController reason = TextEditingController();
    final String? submitted = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.storesDialogReportFailure),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: l10n.storesFieldReason),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.storesActionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(reason.text.trim()),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );

    reason.dispose();
    if (submitted == null || submitted.isEmpty) return;

    try {
      await repo.fail(id, submitted);
      messenger.showSnackBar(const SnackBar(content: Text('Reported')));
      _reload();
    } on StoresApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Per-status lifecycle controls, mirroring `DELIVERY_TRANSITIONS` on the
  /// server (`assigned → accepted → picked_up → out_for_delivery`).
  ///
  /// The `out_for_delivery` row is the ONLY one that can complete: BR-29
  /// requires the customer's OTP, so there is no bare "Delivered" button.
  Widget? _actions(BuildContext context, Map<String, dynamic> row, String status) {
    switch (status) {
      case 'assigned':
        return ElevatedButton(
          onPressed: () => _advance(context, row, 'accepted'),
          child: const Text('Accept'),
        );
      case 'accepted':
        return ElevatedButton(
          onPressed: () => _advance(context, row, 'picked_up'),
          child: const Text('Pick up'),
        );
      case 'picked_up':
        return ElevatedButton(
          onPressed: () => _advance(context, row, 'out_for_delivery'),
          child: const Text('Out for delivery'),
        );
      case 'out_for_delivery':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Report failure',
              onPressed: () => _fail(context, row),
              icon: const Icon(Icons.report_gmailerrorred_outlined),
            ),
            IconButton(
              tooltip: 'Customer OTP',
              onPressed: () => _verifyOtp(context, row),
              icon: const Icon(Icons.qr_code_scanner_outlined),
            ),
          ],
        );
      default:
        return null;
    }
  }

  /// The drop-off address lives on the ORDER, and the partner order routes are
  /// `storeAuth`-scoped (a driver token cannot pass them). This sheet is the one place the
  /// rider sees WHERE to go, fetched lazily on tap so the list stays a single request.
  Future<void> _showOrder(
    BuildContext context,
    Map<String, dynamic> delivery,
  ) async {
    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();
    final String? id = delivery['_id']?.toString();
    if (id == null) return;
    final String status = '${delivery['status'] ?? ''}';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: repo.deliveryOrder(id),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 220,
                      child: StoresErrorView(error: snapshot.error),
                    );
                  }

                  final Map<String, dynamic> order =
                      (snapshot.data?['order'] as Map?)
                          ?.cast<String, dynamic>() ??
                      <String, dynamic>{};
                  final Map<String, dynamic> address =
                      (order['address'] as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{};
                  final String addressText = <dynamic>[
                    address['line1'],
                    address['line2'],
                    address['area'],
                    address['locality'],
                    address['city'],
                    address['pincode'],
                  ]
                      .whereType<String>()
                      .where((String part) => part.trim().isNotEmpty)
                      .join(', ');
                  final dynamic location = address['location'];
                  final List<dynamic>? coordinates =
                      location is Map ? location['coordinates'] as List<dynamic>? : null;
                  final String? contact = address['contact']?.toString();
                  final dynamic note = order['customerNote'];
                  final num? cod = order['codAmount'] as num?;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Order #${order['orderNo'] ?? ''}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (address['name'] != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            'Deliver to: ${address['name']}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                        if (addressText.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(addressText),
                        ],
                        if (contact != null) ...<Widget>[
                          const SizedBox(height: 4),
                          SelectableText('Contact: $contact'),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            Chip(label: Text('${order['paymentMode'] ?? ''}')),
                            Chip(label: Text('${order['itemCount'] ?? 0} items')),
                            if (order['grandTotal'] != null)
                              Chip(label: Text('Total ${order['grandTotal']}')),
                            if (cod != null && cod != 0)
                              Chip(label: Text('Collect COD $cod')),
                          ],
                        ),
                        if (note != null && '$note'.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            'Customer note: $note',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            if (coordinates != null && coordinates.length == 2)
                              OutlinedButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query='
                                    '${coordinates[1]},${coordinates[0]}',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Navigate'),
                              ),
                            const Spacer(),
                            if (status == 'out_for_delivery')
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _verifyOtp(context, delivery);
                                },
                                icon: const Icon(Icons.qr_code_scanner_outlined),
                                label: const Text('Handover OTP'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleDeliveries),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.map((String status) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: _status == status,
                    onSelected: (bool selected) {
                      // The list endpoint returns the driver's latest 50 with no server-side
                      // status filter, so filtering is local - and therefore the chip must
                      // NOT trigger a refetch.
                      setState(() => _status = selected ? status : null);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StoresAsyncView<Map<String, dynamic>>(
              future: _future!,
              builder: (BuildContext context, Map<String, dynamic> data) {
                final dynamic raw = data['items'] ?? data['deliveries'] ?? data['results'] ?? data;
                final List<Map<String, dynamic>> rows = raw is List
                    ? raw.whereType<Map<String, dynamic>>().toList()
                    : <Map<String, dynamic>>[];
                final List<Map<String, dynamic>> visible = _status == null
                    ? rows
                    : rows
                          .where((Map<String, dynamic> row) => '${row['status']}' == _status)
                          .toList();

                if (visible.isEmpty) {
                  return const StoresEmptyView(
                    message: 'Nothing assigned right now.',
                    icon: Icons.list_alt_outlined,
                  );
                }

                return ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> row = visible[index];
                    final String status = '${row['status'] ?? 'unknown'}';
                    final String statusLabel = status.replaceAll('_', ' ');
                    final bool isCod = (row['codAmount'] ?? 0) != 0 || row['codStatus'] == 'pending';

                    return ListTile(
                      onTap: () => _showOrder(context, row),
                      leading: Icon(
                        isCod ? Icons.payments_outlined : Icons.shopping_bag_outlined,
                        color: isCod ? AppColors.expirySoon : null,
                      ),
                      title: Text('Delivery #${row['_id']?.toString().substring(0, 6) ?? '-'}'),
                      subtitle: Text(
                        isCod ? '$statusLabel - COD ${row['codAmount'] ?? 0}' : statusLabel,
                      ),
                      isThreeLine: false,
                      trailing: _actions(context, row, status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
