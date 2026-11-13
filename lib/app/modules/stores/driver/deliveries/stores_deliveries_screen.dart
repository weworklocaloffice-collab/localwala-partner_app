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
  String? _status;

  static const List<String> _filters = <String>[
    'assigned',
    'picked_up',
    'out_for_delivery',
    'delivered',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    _repo = StoresDriverRepository();
  }

  void _reload() {
    setState(() => _repo = StoresDriverRepository());
  }

  Future<void> _verifyOtp(BuildContext context, Map<String, dynamic> delivery) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();

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
                      setState(() => _status = selected ? status : null);
                      _reload();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StoresAsyncView<Map<String, dynamic>>(
              future: repo.deliveries(status: _status),
              builder: (BuildContext context, Map<String, dynamic> data) {
                final dynamic raw = data['items'] ?? data['deliveries'] ?? data['results'] ?? data;
                final List<Map<String, dynamic>> rows = raw is List
                    ? raw.whereType<Map<String, dynamic>>().toList()
                    : <Map<String, dynamic>>[];

                if (rows.isEmpty) {
                  return const StoresEmptyView(
                    message: 'Nothing assigned right now.',
                    icon: Icons.list_alt_outlined,
                  );
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> row = rows[index];
                    final String status = '${row['status'] ?? 'unknown'}';
                    final bool isCod = (row['codAmount'] ?? 0) != 0 || row['codStatus'] == 'pending';

                    return ListTile(
                      leading: Icon(
                        isCod ? Icons.payments_outlined : Icons.shopping_bag_outlined,
                        color: isCod ? AppColors.expirySoon : null,
                      ),
                      title: Text('Delivery #${row['_id']?.toString().substring(0, 6) ?? '—'}'),
                      subtitle: Text(isCod ? '$status · COD ${row['codAmount'] ?? 0}' : status),
                      trailing: status == 'out_for_delivery'
                          ? Row(
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
                            )
                          : null,
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
