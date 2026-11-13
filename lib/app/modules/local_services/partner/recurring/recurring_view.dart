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

/// Recurring agreements screen for partners.
/// Shows recurring agreements and allows creation/management.
class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _agreementName = TextEditingController();
  final TextEditingController _interval = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _occurrences = TextEditingController();

  bool _loading = true;
  String? _error;
  List<dynamic> _agreements = const <dynamic>[];

  @override
  void dispose() {
    _agreementName.dispose();
    _interval.dispose();
    _price.dispose();
    _occurrences.dispose();
    super.dispose();
  }

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
      final DioApiResponse response = await _repository.recurring();
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _agreements = body['results'] ?? body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _createAgreement() async {
    if (_agreementName.text.trim().isEmpty || _price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.ls_agreement_name_price_required ?? 'Agreement name and price required')),
      );
      return;
    }
    try {
      await _repository.createOffering(<String, dynamic>{
        'service': _agreementName.text.trim(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
      });
      _agreementName.clear();
      _price.clear();
      _interval.clear();
      _occurrences.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)?.ls_recurring_agreements ?? 'Recurring Agreements',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Create new agreement
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _agreementName,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_agreement_name ?? 'Agreement name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
      Expanded(
        child: TextField(
          controller: _interval,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_interval ?? 'Interval (e.g. weekly, monthly)',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _occurrences,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_occurrences ?? 'Occurrences',
            border: const OutlineInputBorder(),
            hintText: 'e.g. 12',
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _price,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_price ?? 'Price',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g. 499',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createAgreement,
                    child: Text(AppLocalizations.of(context)?.ls_create_agreement ?? 'Create Agreement'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Existing agreements list
          Text(
            AppLocalizations.of(context)?.ls_existing_agreements ?? 'Existing Agreements',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _agreements.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)?.ls_no_recurring_agreements ?? 'No recurring agreements yet'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _agreements.length,
                          itemBuilder: (BuildContext context, int i) {
                            final dynamic a = _agreements[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(a['agreementCode'] ?? (AppLocalizations.of(context)?.ls_agreement ?? 'Agreement')),
                                subtitle: Text(
                                  'Interval: ${a['interval'] ?? 'weekly'} · '
                                  'Occurrences: ${a['occurrences'] ?? 0} · '
                                  'Price: ₹${a['price'] ?? 0}',
                                ),
                              ),
                            );
                          }),
        ],
      ),
    );
  }
}