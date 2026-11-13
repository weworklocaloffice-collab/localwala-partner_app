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

import 'package:flutter/material.dart';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/jhatka/partner/session/jhatka_session_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Pick which counter to work. Opened from the dashboard header.
///
/// Shows every permitted outlet with its status — a suspended counter is visible
/// but refuses non-owner/manager roles, and the refusal names the status rather
/// than failing silently. Single-outlet logins see one row and nothing to do,
///
/// which is correct: the sheet must not invent complexity for the common case.
class OutletSwitcherSheet extends StatefulWidget {
  const OutletSwitcherSheet({super.key});

  @override
  State<OutletSwitcherSheet> createState() => _OutletSwitcherSheetState();
}

class _OutletSwitcherSheetState extends State<OutletSwitcherSheet> {
  final JhatkaSessionRepository _repository = JhatkaSessionRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _outlets = const <dynamic>[];
  String? _switchingTo;

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
    final DioApiResponse response = await _repository.outlets();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load counters.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _outlets = (body['outlets'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _switch(String outletId) async {
    setState(() => _switchingTo = outletId);
    final DioApiResponse response = await _repository.switchOutlet(
      outletId: outletId,
    );
    if (!mounted) return;
    setState(() => _switchingTo = null);
    if (response.errorType != NetErrorType.none) {
      String message = 'Switch did not go through. Retry.';
      try {
        final Map<String, dynamic> err = decodeBody(response);
        final String detail = (err['message'] ?? '').toString();
        if (detail.isNotEmpty) message = detail;
      } catch (_) {
        message = 'Switch did not go through. Retry.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    // The server persisted lastActiveOutletId; the app re-opens here next login.
    // Pop with the new id so the caller can refresh everything it holds.
    Navigator.of(context).pop(outletId);
  }

  @override
  Widget build(BuildContext context) {
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
            'Work at',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'One business, many counters. Switching persists — next login opens here.',
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!)
          else if (_outlets.isEmpty)
            Text(AppLocalizations.of(context)!.jhatkaNoCounters)
          else
            ..._outlets.map((dynamic raw) {
              final Map<String, dynamic> outlet = Map<String, dynamic>.from(
                raw as Map,
              );
              final String id = (outlet['id'] ?? outlet['_id'] ?? '')
                  .toString();
              final String status = (outlet['status'] ?? '').toString();
              final bool busy = _switchingTo == id;
              return Card(
                child: ListTile(
                  title: Text((outlet['name'] ?? 'Counter').toString()),
                  subtitle: Text(status.isEmpty ? '' : 'Status: $status'),
                  trailing: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: busy ? null : () => _switch(id),
                ),
              );
            }),
        ],
      ),
    );
  }
}
