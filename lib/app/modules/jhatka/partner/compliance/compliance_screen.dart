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
import 'package:partner/app/modules/jhatka/partner/compliance/jhatka_compliance_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Compliance: licence status, FSSAI submission, complaints, reviews.
///
/// An expired licence blocks new orders server side while in-flight orders
/// continue — so this screen leads with status, not with forms. A review
/// response is once-only; a complaint response appends to the trail.
class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  final JhatkaComplianceRepository _repository = JhatkaComplianceRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _status = const <String, dynamic>{};
  List<dynamic> _complaints = const <dynamic>[];
  List<dynamic> _reviews = const <dynamic>[];
  Map<String, dynamic> _reviewSummary = const <String, dynamic>{};
  List<dynamic> _promotions = const <dynamic>[];
  String? _actingOn;

  final TextEditingController _licence = TextEditingController();
  final TextEditingController _expiry = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _licence.dispose();
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final List<DioApiResponse> results =
        await Future.wait(<Future<DioApiResponse>>[
          _repository.status(),
          _repository.complaints(),
          _repository.reviews(),
          _repository.promotions(),
        ]);
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load compliance.';
      });
      return;
    }
    final Map<String, dynamic> reviewsBody = decodeBody(results[2]);
    setState(() {
      _loading = false;
      _status = Map<String, dynamic>.from(decodeBody(results[0]));
      _complaints =
          (decodeBody(results[1])['complaints'] as List?) ?? const <dynamic>[];
      _reviews = (reviewsBody['reviews'] as List?) ?? const <dynamic>[];
      _reviewSummary = Map<String, dynamic>.from(
        (reviewsBody['summary'] ?? {}) as Map,
      );
      _promotions =
          (decodeBody(results[3])['promotions'] as List?) ?? const <dynamic>[];
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

  Future<void> _messageSheet({
    required String title,
    required String key,
    required Future<DioApiResponse> Function(String message) call,
  }) async {
    final TextEditingController message = TextEditingController();
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: message,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldMessageRequired,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionSend),
                ),
              ),
            ],
          ),
        );
      },
    );
    final String text = message.text.trim();
    message.dispose();
    if (go != true || text.isEmpty || !mounted) return;
    await _act(key, () => call(text));
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavCompliance,
      icon: Icons.verified_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaComplianceUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _statusCard(),
          _fssaiCard(),
          _sectionTitle('Complaints (${_complaints.length})'),
          ..._complaints.map(_complaintTile),
          const SizedBox(height: 12),
          _sectionTitle(
            'Reviews · ${_reviewSummary['total'] ?? 0} · '
            'avg ${_reviewSummary['averageRating'] ?? '—'}',
          ),
          ..._reviews.map(_reviewTile),
          const SizedBox(height: 12),
          _sectionTitle('Promotions (${_promotions.length})'),
          ..._promotions.map(_promotionTile),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _actingOn != null ? null : _promotionSheet,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  AppLocalizations.of(context)!.storesDialogNewPromotion,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusCard() {
    final String status = (_status['status'] ?? 'missing').toString();
    final bool blocked = status == 'expired' || status == 'revoked';
    return Card(
      child: ListTile(
        leading: Icon(
          blocked ? Icons.block_outlined : Icons.verified_outlined,
          color: blocked ? AppColors.expired : AppColors.canInStore,
        ),
        title: Text(AppLocalizations.of(context)!.jhatkaFssaiLabel(status)),
        subtitle: Text(
          (_status['statusLabel'] ??
                  'New orders are blocked while this is expired. In-flight orders continue.')
              .toString(),
        ),
        // Owner-only outlet profile edit. Partial update server-side: the sheet
        // sends only what changed, so editing the phone number cannot wipe the
        // hours another manager just set.
        trailing: IconButton(
          tooltip: AppLocalizations.of(context)!.jhatkaActionEditOutletProfile,
          icon: const Icon(Icons.edit_outlined),
          onPressed: _actingOn != null ? null : _outletSheet,
        ),
      ),
    );
  }

  Future<void> _outletSheet() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController email = TextEditingController();
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
                'Outlet profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.jhatkaBlankUnchanged),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldOutletName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.jhatkaFieldPhone,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.jhatkaFieldEmail,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(AppLocalizations.of(context)!.storesActionSave),
                ),
              ),
            ],
          ),
        );
      },
    );
    final String nameText = name.text.trim();
    final String phoneText = phone.text.trim();
    final String emailText = email.text.trim();
    name.dispose();
    phone.dispose();
    email.dispose();
    if (go != true || !mounted) return;
    if (nameText.isEmpty && phoneText.isEmpty && emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaNothingToSave),
        ),
      );
      return;
    }
    await _act(
      'outlet:edit',
      () => _repository.updateOutlet(
        name: nameText.isEmpty ? null : nameText,
        phone: phoneText.isEmpty ? null : phoneText,
        email: emailText.isEmpty ? null : emailText,
      ),
    );
  }

  Widget _fssaiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Submit FSSAI licence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licence,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.jhatkaFieldLicenceNumber,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiry,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.jhatkaFieldExpiryDate,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _actingOn != null
                  ? null
                  : () {
                      if (_licence.text.trim().isEmpty ||
                          _expiry.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Licence number and expiry are required.',
                            ),
                          ),
                        );
                        return;
                      }
                      _act(
                        'fssai',
                        () => _repository.submitFssai(
                          licenceNumber: _licence.text.trim(),
                          expiresAt: _expiry.text.trim(),
                        ),
                      );
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionSubmitForApproval,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _complaintTile(dynamic raw) {
    final Map<String, dynamic> complaint = Map<String, dynamic>.from(
      raw as Map,
    );
    final String id = (complaint['id'] ?? complaint['_id'] ?? '').toString();
    final String status = (complaint['status'] ?? '').toString();
    final bool busy = _actingOn == 'complaint:$id';
    final List<dynamic> responses =
        (complaint['responses'] as List?) ?? const <dynamic>[];
    return Card(
      child: ExpansionTile(
        title: Text((complaint['subject'] ?? 'Complaint').toString()),
        subtitle: Text(status.isEmpty ? '—' : status),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : StatusChip(
                label: status.isEmpty ? '—' : status,
                color: AppColors.grey,
              ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text((complaint['description'] ?? '').toString()),
                if (responses.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.jhatkaResponsesOnRecord(responses.length),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _messageSheet(
                    title: AppLocalizations.of(
                      context,
                    )!.jhatkaActionRespondComplaint,
                    key: 'complaint:$id',
                    call: (String message) => _repository.respondComplaint(
                      complaintId: id,
                      response: message,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionRespond,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(dynamic raw) {
    final Map<String, dynamic> review = Map<String, dynamic>.from(raw as Map);
    final String id = (review['id'] ?? review['_id'] ?? '').toString();
    final bool busy = _actingOn == 'review:$id';
    final bool responded = review['ownerResponse'] != null;
    return Card(
      child: ListTile(
        title: Text(
          '${'★' * (((review['rating'] as num?) ?? 0).toInt())} '
          '${(review['comment'] ?? '').toString()}',
        ),
        subtitle: responded
            ? Text(AppLocalizations.of(context)!.jhatkaResponded)
            : Text(AppLocalizations.of(context)!.jhatkaAwaitingResponse),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : responded
            ? null
            : TextButton(
                onPressed: () => _messageSheet(
                  title: AppLocalizations.of(
                    context,
                  )!.jhatkaActionRespondReview,
                  key: 'review:$id',
                  call: (String message) => _repository.respondReview(
                    reviewId: id,
                    response: message,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.jhatkaActionRespond),
              ),
      ),
    );
  }

  Widget _promotionTile(dynamic raw) {
    final Map<String, dynamic> promo = Map<String, dynamic>.from(raw as Map);
    return Card(
      child: ListTile(
        title: Text('${promo['code'] ?? '—'} · ${promo['name'] ?? ''}'),
        subtitle: Text(
          '${promo['type'] ?? ''} ${promo['value'] ?? ''} · '
          '${promo['status'] ?? ''}',
        ),
      ),
    );
  }

  /// New promotion. Owner-only server-side; code must be unique per outlet.
  ///
  /// `type` is percent or flat — the server validates the shape, so the sheet
  /// offers the two honestly rather than free text that fails cryptically.
  Future<void> _promotionSheet() async {
    final TextEditingController code = TextEditingController();
    final TextEditingController name = TextEditingController();
    final TextEditingController value = TextEditingController();
    String type = 'percent';
    final bool? go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
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
                    'New promotion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: code,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.jhatkaFieldCode,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.realEstateExecName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.jhatkaFieldType,
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'percent',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaPercentOff,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'flat',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaFlatAmountOff,
                        ),
                      ),
                    ],
                    onChanged: (String? v) {
                      if (v != null) setSheetState(() => type = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: type == 'percent' ? 'Percent' : 'Amount (Rs)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.jhatkaActionCreatePromotion,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    final String codeText = code.text.trim();
    final String nameText = name.text.trim();
    final num? valueNum = num.tryParse(value.text.trim());
    code.dispose();
    name.dispose();
    value.dispose();
    if (go != true || !mounted) return;
    if (codeText.isEmpty || nameText.isEmpty || valueNum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaCodeNameValueRequired,
          ),
        ),
      );
      return;
    }
    await _act(
      'promotion:create',
      () => _repository.createPromotion(
        code: codeText,
        name: nameText,
        type: type,
        value: valueNum,
      ),
    );
  }
}
