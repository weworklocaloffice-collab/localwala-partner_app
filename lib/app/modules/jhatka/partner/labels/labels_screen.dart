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
import 'package:partner/app/modules/jhatka/partner/labels/jhatka_labels_repository.dart';
import 'package:partner/app/modules/jhatka/partner/labels/label_detail_screen.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The food-safety label console.
///
/// Labels are created by weighing (one per packed line), and this screen
/// moves them along: print → apply, or void with a written reason. The only
/// artefact a regulator reads, so every row shows the trace batch.
/// Duplicate generation on a line is refused server side (409) — a retry
/// that arrives here as an error means the label already exists; reload.
class LabelsScreen extends StatefulWidget {
  const LabelsScreen({super.key});

  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  final JhatkaLabelsRepository _repository = JhatkaLabelsRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _labels = const <dynamic>[];
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
    final DioApiResponse response = await _repository.labels();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load labels.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _labels = (body['labels'] as List?) ?? const <dynamic>[];
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

  Future<void> _voidSheet(String labelId) async {
    final TextEditingController reason = TextEditingController();
    final bool? go = await showModalBottomSheet<bool>(
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
              const Text(
                'Void label — reason required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.storesFieldReasonRequired,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionVoidLabel,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    final String text = reason.text.trim();
    reason.dispose();
    if (go != true || text.isEmpty || !mounted) return;
    await _act('void:$labelId', () => _repository.voidLabel(labelId, text));
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavLabels,
      icon: Icons.qr_code_2_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaLabelsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_labels.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaNoLabels,
            message: 'Labels appear here once lines are weighed and packed.',
            icon: Icons.qr_code_2_outlined,
          )
        else
          Card(child: Column(children: _labels.map(_labelTile).toList())),
      ],
    );
  }

  Widget _labelTile(dynamic raw) {
    final Map<String, dynamic> label = Map<String, dynamic>.from(raw as Map);
    final String id = (label['id'] ?? label['_id'] ?? '').toString();
    final String status = (label['status'] ?? '').toString();
    final bool busy = _actingOn != null && _actingOn!.endsWith(id);
    final String batch = (label['qrTraceBatch'] ?? label['batch'] ?? '')
        .toString();
    return ExpansionTile(
      // Tap the header for the full trace (batch, use-by, QR, FSSAI) — the
      // expanded actions stay inline for the quick moves.
      title: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LabelDetailScreen(labelId: id),
            ),
          );
        },
        child: Text(
          '${label['productName'] ?? 'Pack'} · ${label['netQuantity'] ?? ''}',
        ),
      ),
      subtitle: Text('$status${batch.isNotEmpty ? ' · batch $batch' : ''}'),
      trailing: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : StatusChip(
              label: status.isEmpty ? '—' : status,
              color: status == 'applied'
                  ? AppColors.canInStore
                  : AppColors.grey,
            ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (status == 'draft')
                OutlinedButton(
                  onPressed: () =>
                      _act('print:$id', () => _repository.print(id)),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionPrint),
                ),
              if (status == 'printed')
                OutlinedButton(
                  onPressed: () =>
                      _act('apply:$id', () => _repository.apply(id)),
                  child: Text(AppLocalizations.of(context)!.storesActionApply),
                ),
              if (status == 'draft' || status == 'printed')
                OutlinedButton(
                  onPressed: () => _voidSheet(id),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionVoid),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
