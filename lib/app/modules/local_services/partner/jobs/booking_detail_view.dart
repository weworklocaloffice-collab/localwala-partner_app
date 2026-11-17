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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:partner/app/modules/local_services/models/booking.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/models/quote.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Job detail: header, price, quotes (submit + revise), assignment,
/// timeline and status actions. Everything actionable re-checks ownership
/// server-side; 403 surfaces as a message, never a silent no-op.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _labour = TextEditingController();
  final TextEditingController _parts = TextEditingController();

  bool _loading = true;
  bool _hasInvoice = false;
  bool _downloadingInvoice = false;
  String? _error;
  LsBooking? _booking;
  List<LsQuote> _quotes = <LsQuote>[];
  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _staffOptions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _resourceOptions = <Map<String, dynamic>>[];
  String? _selectedStaff;
  String? _selectedResource;

  @override
  void dispose() {
    _labour.dispose();
    _parts.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _idOf(dynamic value) {
    if (value is Map<String, dynamic>) {
      return '${value['_id'] ?? value['id'] ?? ''}';
    }
    if (value == null) return '';
    return '$value';
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    Future<DioApiResponse> call,
  ) async {
    try {
      final DioApiResponse response = await call;
      final Map<String, dynamic> body = decodeBody(response);
      final List<dynamic> raw =
          (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      return raw.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse response = await _repository.bookingDetail(
        widget.bookingId,
      );
      final Map<String, dynamic> body = decodeBody(response);
      final dynamic b = body['booking'];
      final List<dynamic> quotes = (body['quotes'] ?? []) as List<dynamic>;
      final List<dynamic> history = (body['history'] ?? []) as List<dynamic>;
      final List<Map<String, dynamic>> staffRows = await _fetchList(
        _repository.staff(),
      );
      final List<Map<String, dynamic>> resourceRows = await _fetchList(
        _repository.resources(),
      );
      setState(() {
        _booking = b is Map<String, dynamic> ? LsBooking.fromJson(b) : null;
        _hasInvoice = body['invoice'] != null;
        _quotes = quotes
            .whereType<Map<String, dynamic>>()
            .map(LsQuote.fromJson)
            .toList();
        _history = history.whereType<Map<String, dynamic>>().toList();
        final dynamic a = body['assignment'];
        _assignment = a is Map<String, dynamic> ? a : null;
        _staffOptions = staffRows;
        _resourceOptions = resourceRows;
        _selectedStaff = _assignment == null
            ? null
            : _idOf(_assignment!['staff']);
        _selectedResource = _assignment == null
            ? null
            : _idOf(_assignment!['resource']);
        if (_selectedStaff != null && _selectedStaff!.isEmpty) {
          _selectedStaff = null;
        }
        if (_selectedResource != null && _selectedResource!.isEmpty) {
          _selectedResource = null;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _transition(String status) async {
    try {
      await _repository.transitionBooking(widget.bookingId, status);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  Future<void> _submitQuote() async {
    final double? labour = double.tryParse(_labour.text.trim());
    final double? parts = double.tryParse(_parts.text.trim());
    if (labour == null || parts == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.ls_labour_parts_required ?? 'Labour and parts amounts required')),
      );
      return;
    }
    try {
      await _repository.submitQuote(widget.bookingId, <String, dynamic>{
        'labourAmount': labour,
        'partsAmount': parts,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
      });
      _labour.clear();
      _parts.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  Future<void> _reviseQuote(LsQuote quote) async {
    final double? labour = double.tryParse(_labour.text.trim());
    final double? parts = double.tryParse(_parts.text.trim());
    if (labour == null || parts == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.ls_enter_revised_amounts ?? 'Enter revised amounts first')),
      );
      return;
    }
    try {
      await _repository.reviseQuote(quote.id, <String, dynamic>{
        'labourAmount': labour,
        'partsAmount': parts,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
      });
      _labour.clear();
      _parts.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  Future<void> _assign() async {
    try {
      await _repository.assignBooking(
        widget.bookingId,
        staff: (_selectedStaff?.isEmpty ?? true) ? null : _selectedStaff,
        resource: (_selectedResource?.isEmpty ?? true)
            ? null
            : _selectedResource,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  Future<void> _release() async {
    try {
      await _repository.releaseAssignment(widget.bookingId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  Future<void> _downloadInvoice() async {
    setState(() => _downloadingInvoice = true);
    try {
      final Uint8List? bytes = await _repository.invoicePdfBytes(
        widget.bookingId,
      );
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Invoice PDF unavailable');
      }
      final Directory directory = await getApplicationDocumentsDirectory();
      final String safeId = widget.bookingId.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '-',
      );
      final File file = File(
        '${directory.path}${Platform.pathSeparator}'
        'LocalWala_LocalService_Invoice_$safeId.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          title: 'Invoice',
          files: <XFile>[XFile(file.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.ls_failed_error('$e') ??
                  'Failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  String _assignmentLabel() {
    if (_assignment == null) return 'Unassigned';
    final dynamic staff = _assignment!['staff'];
    final dynamic resource = _assignment!['resource'];
    final String staffName = staff is Map<String, dynamic>
        ? '${staff['name'] ?? 'Staff'}'
        : (staff == null ? '-' : '$staff');
    final String resourceName = resource is Map<String, dynamic>
        ? '${resource['name'] ?? 'Resource'}'
        : (resource == null ? '-' : '$resource');
    return 'Staff: $staffName · Resource: $resourceName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_booking?.code ?? 'Job')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? LsErrorState(message: _error!, onRetry: _load)
          : _booking == null
          ? LsEmptyState(
              icon: Icons.work_outline,
              title: AppLocalizations.of(context)?.ls_not_found ?? 'Not found',
              subtitle: 'This booking could not be loaded.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                   Card(
                     child: Padding(
                       padding: const EdgeInsets.all(14),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: <Widget>[
                           Row(
                             children: <Widget>[
                               Expanded(
                                 child: Text(
                                   _booking!.code,
                                   style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                 ),
                               ),
                               LsStatusBadge(status: _booking!.status),
                             ],
                           ),
                           const SizedBox(height: 6),
                           Text(
                             '${_booking!.bookingMode} · Labour ₹${_booking!.labourAmount} · Parts ₹${_booking!.partsAmount}',
                             style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                           ),
                         ],
                       ),
                     ),
                   ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.ls_actions ?? 'Actions',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final String a in _booking!.actions)
                        ElevatedButton(
                          onPressed: () => _transition(a),
                          child: Text(a),
                        ),
                    ],
                  ),
                  if (_hasInvoice) ...<Widget>[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _downloadingInvoice ? null : _downloadInvoice,
                      icon: _downloadingInvoice
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Invoice PDF'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.ls_quotes_title ?? 'Quotes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final LsQuote q in _quotes)
                    Card(
                      child: ListTile(
                        title: Text(
                          '₹${q.labourAmount} + ₹${q.partsAmount} parts',
                        ),
                        subtitle: Text(
                          '${q.status}'
                          '${q.expiresAt == null ? '' : ' · exp ${q.expiresAt}'}',
                        ),
                        trailing: q.status == 'SUBMITTED'
                            ? TextButton(
                                onPressed: () => _reviseQuote(q),
                                child: Text(AppLocalizations.of(context)?.ls_revise ?? 'REVISE'),
                              )
                            : null,
                      ),
                    ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _labour,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '${AppLocalizations.of(context)?.ls_labour ?? 'Labour'} ₹',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _parts,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '${AppLocalizations.of(context)?.ls_parts ?? 'Parts'} ₹',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitQuote,
                        icon: const Icon(Icons.send),
                        tooltip: AppLocalizations.of(context)?.ls_submit_quote ?? 'Submit quote',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.ls_assignment ?? 'Assignment',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_assignmentLabel()),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _staffOptions.any(
                          (Map<String, dynamic> s) =>
                              _idOf(s) == _selectedStaff,
                        )
                        ? _selectedStaff
                        : null,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_staff ?? 'Staff',
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(AppLocalizations.of(context)?.ls_no_staff ?? 'No staff'),
                      ),
                      for (final Map<String, dynamic> s in _staffOptions)
                        DropdownMenuItem<String>(
                          value: _idOf(s),
                          child: Text('${s['name'] ?? 'Staff'}'),
                        ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _selectedStaff = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _resourceOptions.any(
                          (Map<String, dynamic> r) =>
                              _idOf(r) == _selectedResource,
                        )
                        ? _selectedResource
                        : null,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_resource ?? 'Resource',
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(AppLocalizations.of(context)?.ls_no_resource ?? 'No resource'),
                      ),
                      for (final Map<String, dynamic> r in _resourceOptions)
                        DropdownMenuItem<String>(
                          value: _idOf(r),
                          child: Text(
                            '${r['name'] ?? 'Resource'}'
                            '${r['kind'] == null ? '' : ' (${r['kind']})'}',
                          ),
                        ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _selectedResource = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _assign,
                        icon: const Icon(Icons.person_add),
                        label: Text(AppLocalizations.of(context)?.ls_assign ?? 'Assign'),
                      ),
                      const SizedBox(width: 8),
                      if (_assignment != null)
                        TextButton(
                          onPressed: _release,
                          child: Text(AppLocalizations.of(context)?.ls_release ?? 'Release'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.ls_timeline ?? 'Timeline',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final Map<String, dynamic> h in _history)
                    ListTile(
                      dense: true,
                      title: Text('${h['from'] ?? ''} → ${h['to'] ?? ''}'),
                      subtitle: h['reason'] == null
                          ? null
                          : Text('${h['reason']}'),
                    ),
                ],
              ),
            ),
    );
  }
}
