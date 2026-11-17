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
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/stores_permissions.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// One line's pick decision.
///
/// The three choices map to the server's `status` values. "Substituted" is NOT a silent
/// option: BR-31 forbids substituting without a record, so the server answers
/// `SUBSTITUTION_REQUIRES_VARIANT_AND_NOTE` unless both a substitute variant and a note
/// arrive. The UI collects both, rather than letting the partner discover the rule by
/// getting a 422.
class _PickLine {
  _PickLine({
    required this.variant,
    required this.name,
    required this.quantity,
    required this.availableQty,
    this.shelfLocation,
    this.status = 'pending',
  });

  final String variant;
  final String name;
  final int quantity;
  final int availableQty;
  final String? shelfLocation;
  String status;
}

/// Order detail: the line items, the pick, and the packing gate.
///
/// This is where a partner actually works an order. The list screen only answers "what is in
/// the queue"; everything that changes an order's state happens here, in the same order the
/// server's lifecycle allows:
///
///   created -> accepted -> picking -> packing -> ready
///
/// Each button calls the endpoint for the current state rather than offering the whole
/// ladder, because the server's transition table is the authority and a stale client that
/// offers an illegal move just produces a 409.
class StoresOrderDetailScreen extends StatefulWidget {
  const StoresOrderDetailScreen({
    super.key,
    required this.orderId,
    this.permissions,
    this.repository,
  });

  final String orderId;

  /// Test seam: the screen owns the real repository in production, but a widget test
  /// supplies a fake so role gating can be proven without a server.
  final StoresPartnerRepository? repository;

  /// The signed-in role's rights. Null means "not loaded" and keeps every lifecycle
  /// action visible — the server is the authority either way. With a real set, a
  /// dispatcher sees no accept/reject/cancel (§6.23.2) and only delivery-capable
  /// roles get Assign driver.
  final StoresPermissions? permissions;

  @override
  State<StoresOrderDetailScreen> createState() =>
      _StoresOrderDetailScreenState();
}

class _StoresOrderDetailScreenState extends State<StoresOrderDetailScreen> {
  StoresPartnerRepository? _repo;
  List<_PickLine> _lines = <_PickLine>[];
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _delivery;
  bool _busy = false;
  bool _loading = true;

  StoresPermissions get _permissions =>
      widget.permissions ?? StoresPermissions.unknown;

  bool get _mayManageOrders => _permissions.can('orders.write');

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? StoresPartnerRepository();
    _loadAll();
  }

  StoresPartnerRepository get _r => _repo ?? StoresPartnerRepository();

  String get _lifecycle => '${_order?['lifecycle'] ?? ''}';

  String get _titleId {
    final String id = widget.orderId;
    return id.length <= 6 ? id : id.substring(id.length - 6);
  }

  bool get _canAccept =>
      _mayManageOrders &&
      <String>['created', 'paid', 'store_received'].contains(_lifecycle) &&
      ('${_order?['paymentMode']}' == 'cod' ||
          '${_order?['paymentStatus']}' == 'paid');

  bool get _canCancel =>
      _mayManageOrders &&
      <String>[
        'created',
        'payment_pending',
        'paid',
        'store_received',
        'accepted',
        'picking',
        'packing',
        'ready',
      ].contains(_lifecycle);

  bool get _canReject =>
      _mayManageOrders &&
      <String>['created', 'paid', 'store_received'].contains(_lifecycle);

  bool get _canCompletePacking =>
      _mayManageOrders && _lifecycle == 'picking' && _everyLineResolved;

  bool get _canMarkReady => _mayManageOrders && _lifecycle == 'packing';

  bool get _canAssignDriver =>
      _permissions.can('assign_driver') &&
      _lifecycle == 'ready' &&
      _delivery == null;

  bool get _everyLineResolved =>
      _lines.isNotEmpty && _lines.every((_PickLine l) => l.status != 'pending');

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);
    await Future.wait<void>(<Future<void>>[_loadOrder(), _loadPickList()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadOrder() async {
    try {
      final Map<String, dynamic> body = await _r.order(widget.orderId);
      final Map<String, dynamic>? order = (body['order'] as Map?)
          ?.cast<String, dynamic>();
      Map<String, dynamic>? delivery;
      final String lifecycle = '${order?['lifecycle'] ?? ''}';
      if (<String>[
        'driver_assigned',
        'picked_up',
        'out_for_delivery',
        'delivered',
        'completed',
      ].contains(lifecycle)) {
        try {
          final Map<String, dynamic> deliveryBody = await _r.deliveryForOrder(
            widget.orderId,
          );
          delivery = (deliveryBody['delivery'] as Map?)
              ?.cast<String, dynamic>();
        } on StoresApiException {
          delivery = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _delivery = delivery;
      });
    } on StoresApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    }
  }

  Future<void> _loadPickList() async {
    try {
      final Map<String, dynamic> body = await _r.pickList(widget.orderId);
      if (!mounted) return;
      final dynamic raw = body['pickList'] ?? body['picklist'] ?? body['items'];
      final List<Map<String, dynamic>> rows = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _lines = rows
            .map(
              (Map<String, dynamic> r) => _PickLine(
                variant: '${r['variant']}',
                name: '${r['name'] ?? 'Item'}',
                quantity: (r['quantity'] as num?)?.toInt() ?? 0,
                availableQty: (r['availableQty'] as num?)?.toInt() ?? 0,
                shelfLocation: r['shelfLocation']?.toString(),
                status: '${r['status'] ?? 'pending'}',
              ),
            )
            .toList();
      });
    } on StoresApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks the whole line.
  Future<void> _pickAll(_PickLine line) async {
    setState(() => _busy = true);
    try {
      await _r.pickItem(widget.orderId, <String, dynamic>{
        'variant': line.variant,
        'pickedQuantity': line.quantity,
        'status': 'picked',
      });
      _snack('Picked ${line.name}');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Marks the line unavailable. The server books this as a partial fulfilment and the
  /// shortfall is refunded per line (BR-28), never as a share of the whole order.
  Future<void> _markUnavailable(_PickLine line) async {
    setState(() => _busy = true);
    try {
      await _r.pickItem(widget.orderId, <String, dynamic>{
        'variant': line.variant,
        'pickedQuantity': 0,
        'status': 'unavailable',
        'resolution': 'remove',
      });
      _snack('${line.name} marked unavailable');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// BR-31: a substitution must name the substitute and say why. Both fields are
  /// mandatory here, because the server rejects the call otherwise and an order sitting
  /// mid-pick is worse than a slow prompt.
  Future<void> _substitute(_PickLine line) async {
    final TextEditingController variant = TextEditingController();
    final TextEditingController note = TextEditingController();

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.storesDialogSubstituteItem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'A substitution is recorded against the order. It cannot be left blank.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: variant,
                decoration: InputDecoration(
                  labelText: l10n.storesFieldSubstituteVariant,
                ),
              ),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: l10n.storesFieldReasonRequired,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.storesActionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context)!.storesActionRecord),
            ),
          ],
        );
      },
    );

    final String substituteVariant = variant.text.trim();
    final String reason = note.text.trim();
    variant.dispose();
    note.dispose();

    if (go != true || substituteVariant.isEmpty || reason.isEmpty) {
      if (go == true) {
        _snack('A substitute variant and a reason are both required.');
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await _r.pickItem(widget.orderId, <String, dynamic>{
        'variant': line.variant,
        'pickedQuantity': line.quantity,
        'status': 'substituted',
        'substituteVariant': substituteVariant,
        'note': reason,
      });
      _snack('Substitution recorded');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transition(String status) async {
    setState(() => _busy = true);
    try {
      await _r.transitionOrder(widget.orderId, status);
      _snack('Order $status');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completePacking() async {
    final TextEditingController packages = TextEditingController(text: '1');
    final TextEditingController weight = TextEditingController();
    bool fragile = false;

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.storesDialogCompletePacking),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: packages,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.storesFieldPackageCount,
                    ),
                  ),
                  TextField(
                    controller: weight,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.storesFieldWeightGrams,
                    ),
                  ),
                  SwitchListTile(
                    value: fragile,
                    onChanged: (bool v) => setState(() => fragile = v),
                    title: Text(AppLocalizations.of(context)!.storesLabelFragile),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.storesActionCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppLocalizations.of(context)!.storesActionComplete),
                ),
              ],
            );
          },
        );
      },
    );

    final int packageCount = int.tryParse(packages.text) ?? 1;
    final int grams = int.tryParse(weight.text) ?? 0;
    packages.dispose();
    weight.dispose();
    if (go != true) return;

    setState(() => _busy = true);
    try {
      await _r.packing(widget.orderId, <String, dynamic>{
        'packageCount': packageCount,
        'totalWeightGrams': grams,
        'fragile': fragile,
      });
      _snack('Packing recorded');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder({bool reject = false}) async {
    const Map<String, String> reasons = <String, String>{
      'out_of_stock': 'Out of stock',
      'store_closed': 'Store closed',
      'cannot_fulfil': 'Cannot fulfil',
      'pricing_issue': 'Pricing issue',
      'duplicate_order': 'Duplicate order',
      'customer_unreachable': 'Customer unreachable',
      'other': 'Other',
    };
    String reasonCode = reject ? 'cannot_fulfil' : 'out_of_stock';
    final TextEditingController note = TextEditingController();

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(reject ? 'Reject this order?' : 'Cancel this order?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: reasonCode,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: reasons.entries
                        .map(
                          (MapEntry<String, String> e) =>
                              DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() => reasonCode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: reasonCode == 'other'
                          ? 'Note (required)'
                          : 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The reservation is released and any captured online payment is refunded.',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppLocalizations.of(context)!.storesActionKeepOrder),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(reject ? 'Reject order' : 'Cancel order'),
                ),
              ],
            );
          },
        );
      },
    );

    final String noteText = note.text.trim();
    note.dispose();
    if (go != true) return;
    if (reasonCode == 'other' && noteText.isEmpty) {
      _snack('A note is required for “Other”.');
      return;
    }

    final String reason = noteText.isEmpty ? reasons[reasonCode]! : noteText;
    setState(() => _busy = true);
    try {
      if (reject) {
        await _r.rejectOrder(widget.orderId, reason, reasonCode: reasonCode);
      } else {
        await _r.cancelOrder(widget.orderId, reason, reasonCode: reasonCode);
      }
      _snack(reject ? 'Order rejected' : 'Order cancelled');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignDriver() async {
    List<Map<String, dynamic>> drivers;
    setState(() => _busy = true);
    try {
      drivers = await _r.availableDrivers();
    } on StoresApiException catch (e) {
      _snack(e.message);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (drivers.isEmpty) {
      _snack('No available driver at this outlet.');
      return;
    }

    final String? driverId = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.storesActionAssignDriver),
          children: drivers
              .map(
                (Map<String, dynamic> driver) => SimpleDialogOption(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop('${driver['_id']}'),
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text('${driver['driverCode'] ?? AppLocalizations.of(context)!.storesFallbackDriver}'),
                    subtitle: Text(
                      driver['isAvailable'] == true
                          ? 'Available'
                          : 'Unavailable',
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
    if (driverId == null || driverId.isEmpty) return;

    final num fee = (_order?['deliveryFee'] as num?) ?? 0;
    setState(() => _busy = true);
    try {
      await _r.assignDriver(
        orderId: widget.orderId,
        driverId: driverId,
        deliveryFee: fee,
      );
      _snack('Driver assigned');
      await _loadAll();
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool everyLineResolved = _everyLineResolved;
    final Map<String, dynamic>? order = _order;
    final Map<String, dynamic>? delivery = _delivery;
    final Map<String, dynamic>? address = (order?['addressSnapshot'] as Map?)
        ?.cast<String, dynamic>();

    final List<Widget> actions = <Widget>[
      if (_canAccept)
        FilledButton.icon(
          onPressed: _busy ? null : () => _transition('accepted'),
          icon: const Icon(Icons.check),
          label: Text(AppLocalizations.of(context)!.storesActionAcceptOrder),
        ),
      if (_canCompletePacking)
        FilledButton.icon(
          onPressed: _busy ? null : _completePacking,
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(AppLocalizations.of(context)!.storesActionCompletePacking),
        ),
      if (_canMarkReady)
        FilledButton.icon(
          onPressed: _busy ? null : () => _transition('ready'),
          icon: const Icon(Icons.task_alt),
          label: Text(AppLocalizations.of(context)!.storesActionMarkReady),
        ),
      if (_canAssignDriver)
        FilledButton.icon(
          onPressed: _busy ? null : _assignDriver,
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(AppLocalizations.of(context)!.storesActionAssignDriver),
        ),
      if (_canReject)
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _cancelOrder(reject: true),
          icon: const Icon(Icons.block),
          label: Text(AppLocalizations.of(context)!.storesActionReject),
        ),
      if (_canCancel)
        OutlinedButton.icon(
          onPressed: _busy ? null : _cancelOrder,
          icon: const Icon(Icons.cancel_outlined),
          label: Text(AppLocalizations.of(context)!.storesActionCancel),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order?['orderNo'] == null
              ? 'Order $_titleId'
              : 'Order #${order?['orderNo']}',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            if (_loading && order == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (order == null)
              const StoresEmptyView(
                message: 'Order details could not be loaded. Pull to refresh.',
                icon: Icons.receipt_long_outlined,
              )
            else ...<Widget>[
              Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              address?['name']?.toString() ?? 'Customer',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Chip(label: Text(_lifecycle)),
                        ],
                      ),
                      if (address?['contact'] != null)
                        Text('${address?['contact']}'),
                      if (address != null)
                        Text(
                          <String?>[
                                address['line1'],
                                address['line2'],
                                address['area'],
                                address['city'],
                                address['pincode'],
                              ]
                              .where((String? p) => p != null && p.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(color: AppColors.grey),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${order['paymentMode'] ?? 'payment'} · '
                        '${order['paymentStatus'] ?? 'pending'} · '
                        '₹${order['grandTotal'] ?? 0}',
                      ),
                    ],
                  ),
                ),
              ),
              if (delivery != null)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text(
                      'Delivery: ${delivery['status'] ?? 'assigned'}',
                    ),
                    subtitle: Text(
                      'Driver ${(delivery['driver'] as Map?)?['driverCode'] ?? '—'}'
                      '${delivery['otpVerified'] == true ? ' · OTP verified' : ''}',
                    ),
                  ),
                ),
              const StoresSectionHeader(title: 'Pick list'),
              for (final _PickLine line in _lines)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(line.name),
                    subtitle: Text(
                      'Qty ${line.quantity} · available ${line.availableQty}'
                      '${line.shelfLocation == null ? '' : ' · shelf ${line.shelfLocation}'}',
                    ),
                    // The action lives on the line it applies to. A single global
                    // "pick" button would leave the partner guessing which row they
                    // were about to resolve.
                    trailing: line.status == 'pending'
                        ? PopupMenuButton<String>(
                            tooltip: 'Resolve ${line.name}',
                            onSelected: (String choice) {
                              if (choice == 'pick') {
                                _pickAll(line);
                              } else if (choice == 'unavailable') {
                                _markUnavailable(line);
                              } else if (choice == 'substitute') {
                                _substitute(line);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'pick',
                                    child: Text(AppLocalizations.of(context)!.storesLabelPicked),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'unavailable',
                                    child: Text(AppLocalizations.of(context)!.storesLabelUnavailable),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'substitute',
                                    child: Text(AppLocalizations.of(context)!.storesActionSubstitute),
                                  ),
                                ],
                            icon: const Icon(Icons.playlist_add_check),
                          )
                        : Chip(label: Text(line.status)),
                  ),
                ),
              const StoresSectionHeader(title: 'Advance'),
               if (actions.isEmpty)
                 Padding(
                   padding: EdgeInsets.symmetric(horizontal: 16),
                   child: Text(AppLocalizations.of(context)!.storesMsgNoActionAvailable),
                 )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(spacing: 8, runSpacing: 8, children: actions),
                ),
              if (<String>['accepted', 'picking'].contains(_lifecycle) &&
                  !everyLineResolved)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Packing unlocks once every line is picked, marked unavailable, or substituted.',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
