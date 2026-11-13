import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/inventory/bloc/stores_inventory_bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

class StoresInventoryScreen extends StatefulWidget {
  const StoresInventoryScreen({super.key});
  @override
  State<StoresInventoryScreen> createState() => _StoresInventoryScreenState();
}

class _StoresInventoryScreenState extends State<StoresInventoryScreen> {
  StoresPartnerRepository? _repo;
  bool _lowOnly = false;

  static const List<String> _movementTypes = <String>[
    'STOCK_ADDED',
    'STOCK_REMOVED',
    'ADJUSTMENT',
    'DAMAGED',
    'EXPIRED',
  ];

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
  }

  void _reload(BuildContext context, {bool? lowOnly}) {
    final bool value = lowOnly ?? _lowOnly;
    setState(() => _lowOnly = value);
    context.read<StoresInventoryBloc>().add(StoresInventoryLoadEvent(lowOnly: value));
  }

  Future<void> _openAdjust(BuildContext context, Map<String, dynamic> row) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String variant = '${row['variant'] ?? ''}';
    final String product = '${row['product'] ?? ''}';
    if (variant.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.storesMsgNoVariantToAdjust)),
      );
      return;
    }
    String type = _movementTypes.first;
    final TextEditingController qty = TextEditingController(text: '1');
    final TextEditingController reason = TextEditingController();
    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.storesDialogAdjustStock),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButton<String>(
                    value: type,
                    items: _movementTypes
                        .map((String t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (String? value) => setState(() => type = value ?? type),
                  ),
                  TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.storesFieldQuantity),
                  ),
                  TextField(
                    controller: reason,
                    decoration: InputDecoration(labelText: l10n.storesFieldReasonRequired),
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
                  child: Text(l10n.storesActionApply),
                ),
              ],
            );
          },
        );
      },
    );
    if (submitted != true || !mounted) return;
    final int parsedQty = int.tryParse(qty.text) ?? 0;
    if (parsedQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.storesMsgQuantityPositive)),
      );
      return;
    }
    if (reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.storesMsgReasonRequired)),
      );
      return;
    }
    try {
      await repo.adjustStock(
        variant: variant,
        product: product,
        type: type,
        quantity: parsedQty,
        reason: reason.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.storesMsgStockUpdated)));
      _reload(context);
    } on StoresApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code == null ? e.message : '${e.message} (${e.code})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresInventoryBloc>(
      create: (_) => StoresInventoryBloc()..add(const StoresInventoryLoadEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.storesTitleStock),
          actions: <Widget>[
            IconButton(
              onPressed: () => _reload(context, lowOnly: !_lowOnly),
              icon: Icon(_lowOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            ),
            IconButton(onPressed: () => _reload(context), icon: const Icon(Icons.refresh)),
          ],
        ),
        body: BlocBuilder<StoresInventoryBloc, StoresInventoryState>(
          builder: (BuildContext context, StoresInventoryState state) {
            switch (state.status) {
              case StoresInventoryStatus.initial:
              case StoresInventoryStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case StoresInventoryStatus.failure:
                return Center(child: Text(state.message));
              case StoresInventoryStatus.loaded:
                break;
            }
            final List<Map<String, dynamic>> rows = state.rows;
            if (rows.isEmpty) {
              return StoresEmptyView(
                message: _lowOnly ? 'Nothing is running low.' : 'No stock rows yet.',
              );
            }
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> row = rows[index];
                return Semantics(
                  label: '${row['name'] ?? row['productName'] ?? l10n.storesFallbackItem}',
                  child: ListTile(
                    title: Text('${row['name'] ?? row['productName'] ?? l10n.storesFallbackItem}'),
                    subtitle: Text(
                      'On hand ${row['onHand'] ?? 0} · Reserved ${row['reserved'] ?? 0} · '
                      'Available ${row['availableQty'] ?? 0}',
                    ),
                    trailing: (row['availableQty'] as num? ?? 0) <= (row['lowStockThreshold'] as num? ?? 0)
                        ? const Icon(Icons.warning_amber_outlined, color: AppColors.expirySoon)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openAdjust(context, row),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
