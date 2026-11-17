/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
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
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Partner marketing: buy sponsored packages and manage campaigns.
class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _packages = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _campaigns = <Map<String, dynamic>>[];
  String _city = '';
  List<String> _localities = <String>[];
  List<String> _pincodes = <String>[];

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
      final List<DioApiResponse> responses = await Future.wait(<Future<DioApiResponse>>[
        _repository.marketingPackages(),
        _repository.marketingCampaigns(),
        _repository.coverage(),
      ]);
      final Map<String, dynamic> packagesBody = decodeBody(responses[0]);
      final Map<String, dynamic> campaignsBody = decodeBody(responses[1]);
      final Map<String, dynamic> coverageBody = decodeBody(responses[2]);
      final Map<String, dynamic> coverage =
          (coverageBody['coverage'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      setState(() {
        _packages = ((packagesBody['packages'] ?? <dynamic>[]) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList();
        _campaigns = ((campaignsBody['campaigns'] ?? <dynamic>[]) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList();
        _city = '${coverage['city'] ?? ''}';
        _localities = List<String>.from(
          (coverage['localities'] as List?) ?? <dynamic>[],
        ).where((String value) => value.isNotEmpty).toList();
        _pincodes = List<String>.from(
          (coverage['pincodes'] as List?) ?? <dynamic>[],
        ).where((String value) => value.isNotEmpty).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _createCampaign(Map<String, dynamic> package) async {
    final Map<String, dynamic>? payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => _CampaignDialog(
        package: package,
        city: _city,
        localities: _localities,
        pincodes: _pincodes,
      ),
    );
    if (payload == null) return;
    try {
      final DioApiResponse response =
          await _repository.createMarketingCampaign(payload);
      decodeBody(response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.ls_campaign_created ??
                  'Campaign submitted for review',
            ),
          ),
        );
      }
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _pay(String campaignId) async {
    try {
      final DioApiResponse response =
          await _repository.payMarketingCampaign(campaignId);
      decodeBody(response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.ls_payment_initiated ??
                  'Payment initiated',
            ),
          ),
        );
      }
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _updateStatus(String campaignId, String action) async {
    try {
      await _repository.updateMarketingCampaignStatus(campaignId, action);
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }

  void _showCampaignMenu(Map<String, dynamic> campaign) {
    final String status = '${campaign['status'] ?? ''}';
    final String id = '${campaign['_id'] ?? campaign['id'] ?? ''}';
    if (id.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (status == 'live')
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(AppLocalizations.of(context)?.ls_pause ?? 'Pause'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(id, 'pause');
                },
              ),
            if (status == 'paused')
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(AppLocalizations.of(context)?.ls_resume ?? 'Resume'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(id, 'resume');
                },
              ),
            if (<String>[
              'pending_review',
              'approved_unpaid',
              'scheduled',
              'live',
              'paused',
            ].contains(status))
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: Text(AppLocalizations.of(context)?.ls_cancel ?? 'Cancel'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(id, 'cancel');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return LsErrorState(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Text(
            l10n?.ls_my_campaigns ?? 'My campaigns',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_campaigns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n?.ls_no_campaigns ?? 'No campaigns yet'),
            ),
          for (final Map<String, dynamic> campaign in _campaigns)
            Card(
              child: ListTile(
                title: Text('${campaign['caption'] ?? ''}'),
                subtitle: Text(
                  '${campaign['status'] ?? ''} • ${campaign['paymentStatus'] ?? ''}\n'
                  '${_targetLabel(campaign)} • ${_metricLabel(campaign)}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if ('${campaign['status']}' == 'approved_unpaid')
                      TextButton(
                        onPressed: () => _pay(
                          '${campaign['_id'] ?? campaign['id'] ?? ''}',
                        ),
                        child: Text(l10n?.ls_pay ?? 'Pay'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showCampaignMenu(campaign),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n?.ls_marketing_packages ?? 'Marketing packages',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          for (final Map<String, dynamic> package in _packages)
            Card(
              child: ListTile(
                title: Text('${package['name'] ?? package['code'] ?? ''}'),
                subtitle: Text(
                  '${package['placement'] ?? ''} • ${package['targetingLevel'] ?? ''} • '
                  '${package['durationHours'] ?? 0}h • ₹${package['price'] ?? 0}',
                ),
                trailing: TextButton(
                  onPressed: () => _createCampaign(package),
                  child: Text(l10n?.ls_create_campaign ?? 'Create'),
                ),
              ),
            ),
          if (_packages.isEmpty)
            Text(l10n?.ls_no_packages ?? 'No packages available'),
        ],
      ),
    );
  }

  String _targetLabel(Map<String, dynamic> campaign) {
    final String city = '${campaign['city'] ?? ''}';
    final List<dynamic> localities =
        (campaign['targetLocalities'] as List?) ?? <dynamic>[];
    final List<dynamic> pincodes =
        (campaign['targetPincodes'] as List?) ?? <dynamic>[];
    final List<String> parts = <String>[
      if (city.isNotEmpty) city,
      ...localities.map((dynamic value) => '$value'),
      ...pincodes.map((dynamic value) => '$value'),
    ];
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String _metricLabel(Map<String, dynamic> campaign) {
    final Map<String, dynamic> metrics =
        (campaign['metrics'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    return '${metrics['impressions'] ?? 0} impr • ${metrics['clicks'] ?? 0} clicks';
  }
}

class _CampaignDialog extends StatefulWidget {
  const _CampaignDialog({
    required this.package,
    required this.city,
    required this.localities,
    required this.pincodes,
  });

  final Map<String, dynamic> package;
  final String city;
  final List<String> localities;
  final List<String> pincodes;

  @override
  State<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<_CampaignDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _caption = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _pincodes = TextEditingController();
  String? _locality;
  DateTime _start = DateTime.now().add(const Duration(minutes: 15));

  String get _targeting => '${widget.package['targetingLevel'] ?? 'city'}';

  @override
  void initState() {
    super.initState();
    _city.text = widget.city;
    if (widget.localities.isNotEmpty) _locality = widget.localities.first;
    if (widget.pincodes.isNotEmpty) _pincodes.text = widget.pincodes.first;
  }

  @override
  void dispose() {
    _caption.dispose();
    _city.dispose();
    _pincodes.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;
    final DateTime candidate = DateTime(
      date.year,
      date.month,
      date.day,
      _start.hour,
      _start.minute,
    );
    final DateTime minimum = DateTime.now().add(const Duration(minutes: 6));
    setState(() {
      _start = candidate.isBefore(minimum) ? minimum : candidate;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'package': widget.package['_id'] ?? widget.package['id'],
      'caption': _caption.text.trim(),
      'startsAt': _start.toUtc().toIso8601String(),
    };
    if (_targeting == 'locality') {
      payload['localities'] = <String>[_locality ?? ''];
    } else if (_targeting == 'pincode') {
      payload['pincodes'] = _pincodes.text
          .split(',')
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList();
    } else {
      payload['city'] = _city.text.trim();
    }
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final String localStart = '${_start.day}/${_start.month}/${_start.year} '
        '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
    return AlertDialog(
      title: Text('${widget.package['name'] ?? widget.package['code'] ?? ''}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _caption,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Caption'),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              if (_targeting == 'locality')
                DropdownButtonFormField<String>(
                  initialValue: _locality,
                  decoration: const InputDecoration(labelText: 'Locality'),
                  items: widget.localities
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) => setState(() => _locality = value),
                  validator: (String? value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
              if (_targeting == 'pincode')
                TextFormField(
                  controller: _pincodes,
                  decoration: const InputDecoration(
                    labelText: 'Pincodes',
                    helperText: 'Comma separated',
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
              if (_targeting == 'city')
                TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: Text('Starts $localStart')),
                  TextButton(
                    onPressed: _pickStart,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            AppLocalizations.of(context)?.ls_create_campaign ?? 'Create',
          ),
        ),
      ],
    );
  }
}
