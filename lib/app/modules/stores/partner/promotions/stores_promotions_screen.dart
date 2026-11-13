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

import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// Promotions the outlet runs.
///
/// Two things this screen is for:
///
/// 1. **Creating.** The server's required fields are `name`, `type`, `value`,
///    `startsAt` and `endsAt`; a `percent_off` promotion additionally requires a
///    `maxDiscount`. Everything else has a default. `type` is a closed set
///    (`percent_off`, `fixed_off`, `min_order_offer`, `free_delivery`,
///    `product_discount`), so the form uses the server's vocabulary as a dropdown rather
///    than a text field the validation would reject. New promotions are submitted for
///    Admin approval and start as `draft`, never live.
/// 2. **Testing a code.** `POST /promotions/validate` answers whether a code applies to a
///    cart amount and what the discount would be. Partners test a code before printing it
///    on a flyer, not after a customer complains at the counter.
class StoresPromotionsScreen extends StatefulWidget {
  const StoresPromotionsScreen({super.key});

  @override
  State<StoresPromotionsScreen> createState() => _StoresPromotionsScreenState();
}

class _StoresPromotionsScreenState extends State<StoresPromotionsScreen> {
  StoresPartnerRepository? _repo;

  /// The server's closed type set. Mirrors `promotionCreateValidation` — a sixth type must
  /// be added there first.
  static const List<String> _types = <String>[
    'percent_off',
    'fixed_off',
    'min_order_offer',
    'free_delivery',
    'product_discount',
  ];

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
  }

  void _reload() {
    setState(() => _repo = StoresPartnerRepository());
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Promotions and coupons are separate server ledgers but one commercial screen. A
  /// coupon is merged here with `_kind` so the row can label it without pretending its
  /// `name` field is a promotion name.
  Future<List<Map<String, dynamic>>> _loadRows() async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final List<List<Map<String, dynamic>>> both = await Future.wait(
      <Future<List<Map<String, dynamic>>>>[repo.promotions(), repo.coupons()],
    );
    return <Map<String, dynamic>>[
      for (final Map<String, dynamic> row in both[0])
        <String, dynamic>{...row, '_kind': 'promotion'},
      for (final Map<String, dynamic> row in both[1])
        <String, dynamic>{...row, '_kind': 'coupon'},
    ];
  }

  Future<void> _createCoupon() async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    String type = 'percent_off';
    final TextEditingController code = TextEditingController();
    final TextEditingController title = TextEditingController();
    final TextEditingController value = TextEditingController();

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.storesTitleNewCoupon),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Code (required)',
                    ),
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Title (required)',
                    ),
                  ),
                  DropdownButton<String>(
                    value: type,
                    items:
                        const <String>[
                              'percent_off',
                              'fixed_off',
                              'free_delivery',
                            ]
                            .map(
                              (String t) => DropdownMenuItem<String>(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                    onChanged: (String? v) => setState(() => type = v ?? type),
                  ),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppLocalizations.of(context)!.storesActionCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppLocalizations.of(context)!.storesActionCreate),
                ),
              ],
            );
          },
        );
      },
    );

    final String couponCode = code.text.trim().toUpperCase();
    final String couponTitle = title.text.trim();
    final num couponValue = num.tryParse(value.text.trim()) ?? 0;
    code.dispose();
    title.dispose();
    value.dispose();
    if (go != true || couponCode.isEmpty || couponTitle.isEmpty) return;

    final DateTime now = DateTime.now();
    try {
      await repo.createCoupon(<String, dynamic>{
        'code': couponCode,
        'title': couponTitle,
        'type': type,
        'value': couponValue,
        'startsAt': now.toIso8601String(),
        'endsAt': now.add(const Duration(days: 30)).toIso8601String(),
      });
      _snack('Coupon created (30 days)');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _create() async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    String type = _types.first;
    final TextEditingController name = TextEditingController();
    final TextEditingController value = TextEditingController();
    final TextEditingController maxDiscount = TextEditingController();
    final TextEditingController code = TextEditingController();

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.storesDialogNewPromotion),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: l10n.storesFieldNameRequired,
                    ),
                  ),
                  DropdownButton<String>(
                    value: type,
                    items: _types
                        .map(
                          (String t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => type = v ?? type),
                  ),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.storesFieldValueRequired,
                    ),
                  ),
                  TextField(
                    controller: maxDiscount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max discount (required for percent off)',
                    ),
                  ),
                  TextField(
                    controller: code,
                    decoration: InputDecoration(
                      labelText: l10n.storesFieldCodeOptional,
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
                  child: Text(l10n.storesActionCreate),
                ),
              ],
            );
          },
        );
      },
    );

    final String promotionName = name.text.trim();
    final String promotionCode = code.text.trim().toUpperCase();
    final num? promotionValue = num.tryParse(value.text.trim());
    final num? promotionMaxDiscount = num.tryParse(maxDiscount.text.trim());
    name.dispose();
    value.dispose();
    maxDiscount.dispose();
    code.dispose();
    if (go != true || promotionName.isEmpty || promotionValue == null) return;
    if (type == 'percent_off' &&
        (promotionMaxDiscount == null || promotionMaxDiscount <= 0)) {
      _snack('Set a positive max discount for a percent-off promotion.');
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime ends = now.add(const Duration(days: 30));

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'name': promotionName,
        'type': type,
        'value': promotionValue,
        if (promotionCode.isNotEmpty) 'code': promotionCode,
        'startsAt': now.toIso8601String(),
        'endsAt': ends.toIso8601String(),
      };
      if (promotionMaxDiscount != null) {
        body['maxDiscount'] = promotionMaxDiscount;
      }
      await repo.createPromotion(body);
      _snack('Promotion submitted for approval.');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _validateCode() async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final TextEditingController code = TextEditingController();
    final TextEditingController amount = TextEditingController();

    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.storesTitleTestCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: code,
                decoration: InputDecoration(labelText: l10n.storesFieldCode),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.storesFieldCartAmount,
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
              child: Text(l10n.storesActionCreate),
            ),
          ],
        );
      },
    );

    final String testCode = code.text.trim().toUpperCase();
    final num testAmount = num.tryParse(amount.text.trim()) ?? 0;
    code.dispose();
    amount.dispose();
    if (go != true || testCode.isEmpty) return;

    try {
      final Map<String, dynamic> result = await repo.validatePromotion(
        testCode,
        testAmount,
      );
      final dynamic discount = result['discount'];
      _snack(
        discount == null || (discount is num && discount == 0)
            ? 'Code applies, but discounts nothing at this amount.'
            : 'Code gives $discount off.',
      );
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _changePause(Map<String, dynamic> row, bool pause) async {
    final String? id = row['_id']?.toString() ?? row['id']?.toString();
    if (id == null || id.isEmpty) {
      _snack('This promotion has no id.');
      return;
    }
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    try {
      if (pause) {
        await repo.pausePromotion(id);
      } else {
        await repo.resumePromotion(id);
      }
      _snack(pause ? 'Promotion paused.' : 'Promotion resumed.');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitlePromotions),
        actions: <Widget>[
          IconButton(
            tooltip: 'New coupon',
            onPressed: _createCoupon,
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
          IconButton(
            tooltip: 'Test a code',
            onPressed: _validateCode,
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: StoresAsyncView<List<Map<String, dynamic>>>(
        future: _loadRows(),
        builder: (BuildContext context, List<Map<String, dynamic>> rows) {
          if (rows.isEmpty) {
            return const StoresEmptyView(
              message: 'No promotions yet. Create one with +.',
              icon: Icons.local_offer_outlined,
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> row = rows[index];
              final bool isCoupon = row['_kind'] == 'coupon';
              final String status = '${row['status'] ?? 'active'}';
              final String approval =
                  '${(row['approval'] as Map?)?['status'] ?? ''}';
              final String statusLabel =
                  status == 'draft' && approval == 'pending'
                  ? 'pending approval'
                  : status;
              final bool statusIsLive = status == 'active' || status == 'live';
              return ListTile(
                leading: Icon(
                  isCoupon
                      ? Icons.confirmation_number_outlined
                      : Icons.local_offer_outlined,
                ),
                title: Text(
                  '${row['name'] ?? row['title'] ?? (isCoupon ? 'Coupon' : 'Promotion')}',
                ),
                subtitle: Text(
                  '${isCoupon ? 'coupon' : row['type'] ?? ''}'
                  '${row['code'] != null ? ' A� code ${row['code']}' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!statusIsLive) Chip(label: Text(statusLabel)),
                    if (!isCoupon &&
                        <String>[
                          'active',
                          'live',
                          'scheduled',
                          'paused',
                        ].contains(status))
                      PopupMenuButton<bool>(
                        tooltip: 'Pause or resume',
                        onSelected: (bool pause) => _changePause(row, pause),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<bool>>[
                               if (status == 'paused')
                                 PopupMenuItem<bool>(
                                   value: false,
                                   child: Text(AppLocalizations.of(context)!.storesResume),
                                 )
                               else
                                 PopupMenuItem<bool>(
                                   value: true,
                                   child: Text(AppLocalizations.of(context)!.storesPause),
                                 ),
                            ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
