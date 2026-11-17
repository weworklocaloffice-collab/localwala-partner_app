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
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Leads screen for partners.
/// Shows pending leads and allows qualification/invalidation with lead fee handling.
class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _leadName = TextEditingController();
  final TextEditingController _leadValue = TextEditingController();

  bool _loading = true;
  String? _error;
  List<dynamic> _leads = const <dynamic>[];

  static const List<String> _statuses = <String>['pending', 'qualified', 'converted', 'invalid'];

  @override
  void dispose() {
    _leadName.dispose();
    _leadValue.dispose();
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
      final DioApiResponse response = await _repository.leads();
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _leads = body['results'] ?? body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _qualifyLead(String id) async {
    try {
      await _repository.qualifyLead(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')),
        );
      }
    }
  }

  Future<void> _invalidateLead(String id) async {
    try {
      await _repository.invalidateLead(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pendingCount =
        _leads.where((lead) => lead['status'] == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)?.ls_open_leads ?? 'Open Leads',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Summary stats
          Row(
            children: <Widget>[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(AppLocalizations.of(context)?.ls_leads_awaiting_qualification ?? 'Leads awaiting qualification'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      AppLocalizations.of(context)?.ls_manage_lead_claims ?? 'Manage lead claims and charges',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Leads list
          Text(
            AppLocalizations.of(context)?.ls_leads_list ?? 'Leads List',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
            _loading
               ? const Center(child: CircularProgressIndicator())
               : _error != null
                   ? LsErrorState(message: _error!, onRetry: _load)
                   : _leads.isEmpty
                       ? LsEmptyState(
                           icon: Icons.list_outlined,
                           title: AppLocalizations.of(context)?.ls_no_leads ?? 'No leads yet',
                           subtitle: 'New leads will appear here.',
                         )
                       : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _leads.length,
                          itemBuilder: (BuildContext context, int i) {
                            final lead = _leads[i];
                            final String status = lead['status'] ?? 'pending';
                            final double? leadValue =
                                double.tryParse(
                                    '${lead['value'] ?? 0}');
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(lead['name'] ?? 'Lead'),
                                subtitle: Text(
                                  'Status: $status ${leadValue != null ? '· ₹$leadValue' : ''}',
                                ),
                                trailing: status == 'pending'
                                    ? PopupMenuButton<String>(
                                        onSelected: (String value) {
                                          if (value == 'qualified') {
                                            _qualifyLead(lead['_id'] ?? '');
                                          } else if (value == 'invalid') {
                                            _invalidateLead(lead['_id'] ?? '');
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return _statuses.map<PopupMenuItem<String>>((String value) {
                                            return PopupMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList();
                                        },
                                      )
                                    : status == 'qualified'
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : null,
                              ),
                            );
                          }),
          const SizedBox(height: 24),
          // Add lead (for admin or advanced partner use)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _leadName,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_lead_name ?? 'Lead name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _leadValue,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_lead_value ?? 'Lead value',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g. 99',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Would post to leads endpoint - deferred for now
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)?.ls_lead_creation_deferred ?? 'Lead creation deferred')),
                      );
                    },
                    child: Text(AppLocalizations.of(context)?.ls_create_lead ?? 'Create Lead'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}