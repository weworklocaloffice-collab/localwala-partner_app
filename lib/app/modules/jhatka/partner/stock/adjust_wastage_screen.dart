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
import 'package:partner/app/modules/jhatka/partner/stock/jhatka_stock_repository.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Manual stock correction and wastage recording, one screen, two modes.
///
/// Adjustment is a correction toward what was counted; wastage is a cause
/// with a quantity. A reduction that is not a count needs owner authority,
/// and THEFT_LOSS always does — the server refuses the rest, and the refusal
/// is shown as-is rather than translated into something softer.
class AdjustWastageScreen extends StatefulWidget {
  const AdjustWastageScreen({
    super.key,
    required this.items,
    this.initialMode = StockEntryMode.adjust,
  });

  /// Each entry: `id`, `label`, `unit`.
  final List<Map<String, String>> items;
  final StockEntryMode initialMode;

  @override
  State<AdjustWastageScreen> createState() => _AdjustWastageScreenState();
}

enum StockEntryMode { adjust, wastage }

class _AdjustWastageScreenState extends State<AdjustWastageScreen> {
  final JhatkaStockRepository _repository = JhatkaStockRepository();

  late StockEntryMode _mode;
  String? _itemId;
  String? _movementType;
  String? _cause;
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  String? get _itemUnit {
    for (final Map<String, String> item in widget.items) {
      if (item['id'] == _itemId) return item['unit'];
    }
    return null;
  }

  Future<void> _submit() async {
    if (_itemId == null) {
      _say('Pick the stock line first.');
      return;
    }
    final num? qty = num.tryParse(_qty.text.trim());
    if (qty == null) {
      _say('Enter a quantity.');
      return;
    }
    if (_mode == StockEntryMode.adjust) {
      if (_movementType == null) {
        _say('Pick the movement type.');
        return;
      }
      if (_reason.text.trim().isEmpty) {
        _say('A reason is required — corrections without one are stories.');
        return;
      }
    } else {
      if (_cause == null) {
        _say('Pick the cause.');
        return;
      }
      if (qty <= 0) {
        _say('Wastage quantity must be above zero.');
        return;
      }
    }
    setState(() => _busy = true);
    final DioApiResponse response = _mode == StockEntryMode.adjust
        ? await _repository.adjust(
            inventoryItem: _itemId!,
            qtyDelta: qty,
            movementType: _movementType!,
            reason: _reason.text.trim(),
          )
        : await _repository.recordWastage(
            inventoryItem: _itemId!,
            qty: qty,
            unit: _itemUnit ?? 'GRAM',
            cause: _cause!,
            notes: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType == NetErrorType.none) {
      Navigator.of(context).pop(true);
    } else {
      _say('That did not go through. Retry.');
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaActionRecordStockMove,
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<StockEntryMode>(
                  segments: <ButtonSegment<StockEntryMode>>[
                    ButtonSegment<StockEntryMode>(
                      value: StockEntryMode.adjust,
                      label: Text(
                        AppLocalizations.of(context)!.jhatkaActionAdjust,
                      ),
                    ),
                    ButtonSegment<StockEntryMode>(
                      value: StockEntryMode.wastage,
                      label: Text(
                        AppLocalizations.of(context)!.jhatkaNavWastage,
                      ),
                    ),
                  ],
                  selected: <StockEntryMode>{_mode},
                  onSelectionChanged: (Set<StockEntryMode> s) =>
                      setState(() => _mode = s.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _itemId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.jhatkaStockLine,
                    border: OutlineInputBorder(),
                  ),
                  items: widget.items
                      .map(
                        (Map<String, String> item) => DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            '${item['label'] ?? ''} (${item['unit'] ?? ''})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _itemId = v),
                ),
                const SizedBox(height: 12),
                if (_mode == StockEntryMode.adjust)
                  DropdownButtonFormField<String>(
                    initialValue: _movementType,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldMovementType,
                      border: OutlineInputBorder(),
                    ),
                    items: JhatkaStockRepository.manualMovementTypes
                        .map(
                          (String t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => _movementType = v),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _cause,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.jhatkaFieldCause,
                      border: OutlineInputBorder(),
                    ),
                    items: JhatkaStockRepository.wastageCauses
                        .map(
                          (String t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => _cause = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: _mode == StockEntryMode.adjust
                        ? 'Quantity delta (+/-)'
                        : 'Quantity lost',
                    border: const OutlineInputBorder(),
                    suffixText: _itemUnit,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: _mode == StockEntryMode.adjust
                        ? 'Reason (required)'
                        : 'Notes (optional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Record', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
