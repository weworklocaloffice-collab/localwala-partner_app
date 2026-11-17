/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/jhatka/partner/procurement/jhatka_procurement_repository.dart';
import 'package:partner/app/modules/jhatka/partner/procurement/jhatka_receipt_decision_models.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One receipt: quality decisions, totals and the posting gate.
///
/// Stock only moves when the receipt posts, so every pending line has to be
/// accepted or rejected first. Rejection uses the governed reason vocabulary
/// rather than free text, so the rejection-rate report can group causes.
class ReceiptDecisionScreen extends StatefulWidget {
  const ReceiptDecisionScreen({super.key, required this.receipt});

  /// The exact row from `GET /inventory/receipts`, including its lines.
  final Map<String, dynamic> receipt;

  @override
  State<ReceiptDecisionScreen> createState() => _ReceiptDecisionScreenState();
}

class _ReceiptDecisionScreenState extends State<ReceiptDecisionScreen> {
  final JhatkaProcurementRepository _repository = JhatkaProcurementRepository();

  late JhatkaReceipt _receipt;
  List<JhatkaRejectionReason> _reasons = const <JhatkaRejectionReason>[];
  bool _loadingReasons = true;
  String? _reasonsError;
  int? _actingLine;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _receipt = JhatkaReceipt.fromJson(widget.receipt);
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _loadingReasons = true;
      _reasonsError = null;
    });
    final DioApiResponse response = await _repository.rejectionReasons();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loadingReasons = false;
        _reasonsError = AppLocalizations.of(
          context,
        )!.jhatkaReceiptReasonsUnavailable;
      });
      return;
    }
    final List<dynamic> raw =
        (decodeBody(response)['reasons'] as List<dynamic>?) ??
        const <dynamic>[];
    setState(() {
      _loadingReasons = false;
      _reasons = raw
          .map(JhatkaRejectionReason.fromJson)
          .where((JhatkaRejectionReason reason) => reason.code.isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<bool> _refreshReceipt() async {
    final DioApiResponse response = await _repository.receipts();
    if (response.errorType != NetErrorType.none) return false;
    final List<dynamic> raw =
        (decodeBody(response)['receipts'] as List<dynamic>?) ??
        const <dynamic>[];
    for (final dynamic entry in raw) {
      if (entry is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(entry);
      final String id = (map['id'] ?? map['_id'] ?? '').toString();
      if (id != _receipt.id) continue;
      if (!mounted) return false;
      setState(() => _receipt = JhatkaReceipt.fromJson(map));
      return true;
    }
    return false;
  }

  Future<void> _accept(JhatkaReceiptLine line) async {
    final String? note = await _askAcceptNote();
    if (note == null || !mounted) return;
    await _decide(line, accept: true, note: note);
  }

  Future<void> _reject(JhatkaReceiptLine line) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loadingReasons) {
      _say(l10n.jhatkaReceiptNoReasons);
      return;
    }
    if (_reasonsError != null || _reasons.isEmpty) {
      _say(_reasonsError ?? l10n.jhatkaReceiptNoReasons);
      return;
    }
    final _RejectSelection? selection =
        await showModalBottomSheet<_RejectSelection>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext context) =>
              _RejectSheet(reasons: _reasons, lineLabel: line.rawSku),
        );
    if (selection == null || !mounted) return;
    await _decide(
      line,
      accept: false,
      note: selection.note,
      reasonCodes: selection.reasonCodes,
    );
  }

  Future<void> _decide(
    JhatkaReceiptLine line, {
    required bool accept,
    String? note,
    List<String>? reasonCodes,
  }) async {
    setState(() => _actingLine = line.index);
    final DioApiResponse response = accept
        ? await _repository.acceptReceiptLine(
            _receipt.id,
            line.index,
            note: note,
          )
        : await _repository.rejectReceiptLine(
            _receipt.id,
            line.index,
            reasonCodes ?? const <String>[],
            note: note,
          );
    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() => _actingLine = null);
      _say(_errorText(response));
      return;
    }

    final bool refreshed = await _refreshReceipt();
    if (!mounted) return;
    setState(() => _actingLine = null);
    if (!refreshed) {
      Navigator.of(context).pop(true);
      return;
    }
    _say(AppLocalizations.of(context)!.jhatkaReceiptDecisionSaved);
  }

  Future<void> _post() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_receipt.canPost) {
      _say(l10n.jhatkaReceiptPostBlocked);
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l10n.jhatkaReceiptPostTitle),
            content: Text(l10n.jhatkaReceiptPostBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.jhatkaActionPostReceipt),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _posting = true);
    final DioApiResponse response = await _repository.postReceipt(_receipt.id);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() => _posting = false);
      _say(_errorText(response));
      return;
    }
    _say(AppLocalizations.of(context)!.jhatkaReceiptPosted);
    Navigator.of(context).pop(true);
  }

  Future<String?> _askAcceptNote() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    String note = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.jhatkaReceiptAcceptTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.jhatkaReceiptAcceptBody),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (String value) => note = value,
              decoration: InputDecoration(
                labelText: l10n.jhatkaFieldNoteOptional,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(note.trim()),
            child: Text(l10n.jhatkaActionAcceptLine),
          ),
        ],
      ),
    );
  }

  String _errorText(DioApiResponse response) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? code = receiptErrorCodeFromBody(
      response.response?.data?.toString(),
    );
    if (code == 'QUALITY_DECISION_PENDING') {
      return l10n.jhatkaReceiptPostBlocked;
    }
    if (code == 'REVERSE_BATCH_FIRST') {
      return l10n.jhatkaReceiptReverseBatchFirst;
    }
    if (code == 'RECEIPT_ALREADY_POSTED') {
      return l10n.jhatkaReceiptAlreadyPosted;
    }
    return l10n.jhatkaDidNotGoThrough;
  }

  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _reasonLabel(String code) {
    for (final JhatkaRejectionReason reason in _reasons) {
      if (reason.code == code) return reason.label;
    }
    return code.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool busy = _actingLine != null || _posting;
    return Scaffold(
      appBar: AppBar(title: Text('Receipt ${_receipt.receiptNo}')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshReceipt();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _summaryCard(),
            if (_receipt.isDraft && _receipt.pendingLineCount > 0) ...<Widget>[
              const SizedBox(height: 12),
              _banner(
                icon: Icons.pending_actions_outlined,
                color: AppColors.accent,
                message: l10n.jhatkaReceiptPostBlocked,
              ),
            ],
            if (_loadingReasons) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (_reasonsError != null) ...<Widget>[
              const SizedBox(height: 12),
              _banner(
                icon: Icons.rule_outlined,
                color: AppColors.expirySoon,
                message: _reasonsError!,
                action: TextButton(
                  onPressed: _loadReasons,
                  child: Text(l10n.retry),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Lines (${_receipt.lines.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._receipt.lines.map(
              (JhatkaReceiptLine line) => _lineCard(line, busy: busy),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _receipt.isDraft
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _receipt.canPost && !busy ? _post : null,
                    icon: _posting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(l10n.jhatkaActionPostReceipt),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _summaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                StatusChip(
                  label: _receipt.status,
                  color: _receipt.isDraft ? AppColors.accent : AppColors.grey,
                ),
                StatusChip(
                  label: _human(_receipt.qualityStatus),
                  color: _qualityColor(_receipt.qualityStatus),
                ),
                if (_receipt.pendingLineCount > 0)
                  StatusChip(
                    label:
                        '${AppLocalizations.of(context)!.jhatkaReceiptDecisionPending} '
                        '${_receipt.pendingLineCount}',
                    color: AppColors.expirySoon,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_receipt.supplierName != null)
              Text('Supplier: ${_receipt.supplierName}'),
            if (_receipt.poNo != null) Text('PO: ${_receipt.poNo}'),
            if (_receipt.receivedAt != null)
              Text('Received: ${_dateText(_receipt.receivedAt!)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: <Widget>[
                _figure(
                  'Accepted value',
                  jhatka_money.formatPaise(_receipt.acceptedValuePaise),
                ),
                _figure(
                  'Rejected value',
                  jhatka_money.formatPaise(_receipt.rejectedValuePaise),
                ),
                _figure(
                  'Rejection rate',
                  '${_receipt.rejectionRatePct.toStringAsFixed(2)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _figure(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          ?action,
        ],
      ),
    );
  }

  Widget _lineCard(JhatkaReceiptLine line, {required bool busy}) {
    final bool lineBusy = _actingLine == line.index;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    line.rawSku.isEmpty
                        ? 'Line ${line.index + 1}'
                        : line.rawSku,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusChip(
                  label: _human(line.qualityStatus),
                  color: _qualityColor(line.qualityStatus),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: <Widget>[
                if (line.receivedQty != null)
                  Text('Received: ${line.receivedQty!.display}'),
                if (line.acceptedQty != null)
                  Text('Accepted: ${line.acceptedQty!.display}'),
                if (line.rejectedQty != null)
                  Text('Rejected: ${line.rejectedQty!.display}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Unit price: ${jhatka_money.formatPaise(line.unitPricePaise)}'
              '  Line value: ${jhatka_money.formatPaise(line.amountPaise)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Payability: ${_human(line.payability)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (line.rejectionReasons.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '${l10n.jhatkaReceiptRejectReasons}: '
                '${line.rejectionReasons.map((JhatkaAppliedRejectionReason reason) => _reasonLabel(reason.code)).join(', ')}',
              ),
              for (final JhatkaAppliedRejectionReason reason
                  in line.rejectionReasons)
                if (reason.note != null)
                  Text(
                    '${_reasonLabel(reason.code)}: ${reason.note}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            ],
            if (line.qualityNotes != null) ...<Widget>[
              const SizedBox(height: 8),
              Text('Note: ${line.qualityNotes}'),
            ],
            if (line.isPending && !line.canDecide) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                l10n.jhatkaReceiptReverseBatchFirst,
                style: TextStyle(color: AppColors.expirySoon),
              ),
            ],
            if (line.canDecide && _receipt.isDraft) ...<Widget>[
              const SizedBox(height: 10),
              if (lineBusy)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy || _loadingReasons
                            ? null
                            : () => _reject(line),
                        child: Text(l10n.jhatkaActionRejectLine),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: busy ? null : () => _accept(line),
                        child: Text(l10n.jhatkaActionAcceptLine),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _human(String value) => value.replaceAll('_', ' ');

  Color _qualityColor(String status) {
    if (status == 'accepted') return AppColors.secondary;
    if (status == 'rejected') return AppColors.expired;
    if (status == 'partially_accepted') return AppColors.expirySoon;
    return AppColors.accent;
  }

  String _dateText(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _RejectSelection {
  const _RejectSelection({required this.reasonCodes, required this.note});

  final List<String> reasonCodes;
  final String note;
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.reasons, required this.lineLabel});

  final List<JhatkaRejectionReason> reasons;
  final String lineLabel;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final Set<String> _codes = <String>{};
  final TextEditingController _note = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toggle(String code, bool selected) {
    setState(() {
      if (selected) {
        _codes.add(code);
      } else {
        _codes.remove(code);
      }
    });
  }

  void _confirm() {
    if (_codes.isEmpty) {
      setState(() => _showValidation = true);
      return;
    }
    Navigator.of(context).pop(
      _RejectSelection(
        reasonCodes: _codes.toList(growable: false),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.jhatkaReceiptRejectTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (widget.lineLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.lineLabel),
              ),
            Text(
              l10n.jhatkaReceiptRejectReasons,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.reasons.length,
                itemBuilder: (BuildContext context, int index) {
                  final JhatkaRejectionReason reason = widget.reasons[index];
                  final String subtitle =
                      <String?>[
                            reason.description,
                            reason.category,
                            reason.severity,
                          ]
                          .whereType<String>()
                          .where((String value) => value.isNotEmpty)
                          .join(' - ');
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _codes.contains(reason.code),
                    onChanged: (bool? value) =>
                        _toggle(reason.code, value ?? false),
                    title: Text(reason.label),
                    subtitle: subtitle.isEmpty ? null : Text(subtitle),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.jhatkaFieldNoteOptional,
              ),
            ),
            if (_showValidation && _codes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.jhatkaReasonRequired,
                  style: const TextStyle(color: AppColors.expired),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirm,
                child: Text(l10n.jhatkaActionRejectLine),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
