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
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<dynamic> _complaints = <dynamic>[];

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
    try {
      final DioApiResponse response = await _repository.complaints();
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _complaints = body['results'] ?? body['data'] ?? <dynamic>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    final DateTime? parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (parsed == null) return '';
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  String _statusLabel(String status) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    switch (status) {
      case 'open':
        return l10n?.ls_open ?? 'Open';
      case 'resolved':
        return l10n?.ls_resolved ?? 'Resolved';
      default:
        return status;
    }
  }

  Future<void> _newTicket() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextEditingController booking = TextEditingController();
    final TextEditingController reason = TextEditingController();
    final String? submittedReason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n?.ls_new_ticket ?? 'New support ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: booking,
                decoration: InputDecoration(
                  labelText:
                      l10n?.ls_ticket_booking_id ?? 'Booking ID (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n?.ls_ticket_reason ?? 'Describe the issue',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.ls_cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String value = reason.text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.ls_ticket_required ??
                            'Please describe the issue',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(l10n?.ls_submit ?? 'Submit'),
            ),
          ],
        );
      },
    );
    if (submittedReason == null) return;
    setState(() => _submitting = true);
    try {
      await _repository.createComplaint(<String, dynamic>{
        if (booking.text.trim().isNotEmpty) 'booking': booking.text.trim(),
        'reason': submittedReason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.ls_ticket_submitted ?? 'Ticket submitted'),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.ls_ticket_failed(e) ?? 'Could not submit: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_support_title ?? 'Support'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _newTicket,
        icon: const Icon(Icons.support_agent),
        label: Text(l10n?.ls_new_ticket ?? 'New ticket'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n?.ls_retry ?? 'Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _complaints.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(top: 48),
                          children: <Widget>[
                            const Icon(Icons.support_outlined, size: 48),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                l10n?.ls_no_complaints ??
                                    'No support tickets yet',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                          itemCount: _complaints.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Map<String, dynamic> complaint =
                                (_complaints[index] as Map)
                                    .cast<String, dynamic>();
                            final String status =
                                '${complaint['status'] ?? 'open'}';
                            final String bookingId =
                                '${complaint['booking'] ?? ''}';
                            final String date =
                                _formatDate(complaint['createdAt']);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  status == 'resolved'
                                      ? Icons.check_circle_outline
                                      : Icons.pending_outlined,
                                  color: status == 'resolved'
                                      ? colors.primary
                                      : colors.tertiary,
                                ),
                                title: Text('${complaint['reason'] ?? ''}'),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${_statusLabel(status)}'
                                      '${date.isEmpty ? '' : ' A� $date'}',
                                    ),
                                    if (bookingId.isNotEmpty)
                                      Text(
                                        '${l10n?.ls_booking ?? 'Booking'}: '
                                        '$bookingId',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
