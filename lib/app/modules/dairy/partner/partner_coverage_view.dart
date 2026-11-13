import 'dart:convert';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:flutter/material.dart';

/// Partner service-area view. The outlet's published locality zone defines its
/// expansion boundary; new localities become deliverable only after review.
class PartnerCoverageScreen extends StatefulWidget {
  const PartnerCoverageScreen({super.key, this.repository});

  final PartnerRepository? repository;

  @override
  State<PartnerCoverageScreen> createState() => _PartnerCoverageScreenState();
}

class _PartnerCoverageScreenState extends State<PartnerCoverageScreen> {
  late final PartnerRepository _repository;
  final TextEditingController _messageController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic> _coverage = <String, dynamic>{};
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PartnerRepository();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final DioApiResponse response = await _repository.coverage();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load delivery coverage. Please try again.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _coverage = Map<String, dynamic>.from(
        (body['coverage'] as Map?) ?? <String, dynamic>{},
      );
      _selected.clear();
    });
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final DioApiResponse response = await _repository.requestCoverage(
      localityIds: _selected.toList(),
      message: _messageController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.errorType != NetErrorType.none) {
      String message = 'Could not submit the service-area request.';
      final dynamic data = response.response?.data;
      if (data is String && data.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(data);
          if (decoded is Map && decoded['message'] is String) {
            message = decoded['message'] as String;
          }
        } on FormatException {
          // Keep the user-facing fallback for a non-JSON response.
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent for platform review.')),
    );
    await _load();
  }

  String _id(Map<String, dynamic> value) =>
      (value['id'] ?? value['_id'] ?? '').toString();

  String _name(dynamic raw) {
    if (raw is Map) {
      final Map<String, dynamic> value = Map<String, dynamic>.from(raw);
      return (value['name'] ?? 'Locality').toString();
    }
    return 'Locality';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> city = Map<String, dynamic>.from(
      (_coverage['city'] as Map?) ?? <String, dynamic>{},
    );
    final List<dynamic> active =
        (_coverage['activeLocalities'] as List?) ?? const <dynamic>[];
    final List<dynamic> nearby =
        (_coverage['nearbyLocalities'] as List?) ?? const <dynamic>[];
    final List<dynamic> zones =
        (_coverage['zoneGroups'] as List?) ?? const <dynamic>[];
    final Map<String, dynamic>? eligibleZone = _coverage['eligibleZone'] is Map
        ? Map<String, dynamic>.from(_coverage['eligibleZone'] as Map)
        : null;
    final Map<String, dynamic>? pending = _coverage['pendingRequest'] is Map
        ? Map<String, dynamic>.from(_coverage['pendingRequest'] as Map)
        : null;
    final Map<String, dynamic>? latest = _coverage['latestRequest'] is Map
        ? Map<String, dynamic>.from(_coverage['latestRequest'] as Map)
        : null;
    Set<String> idsFor(dynamic raw) {
      if (raw is! List) return <String>{};
      return raw
          .map((dynamic item) => item is Map
              ? _id(Map<String, dynamic>.from(item))
              : item?.toString() ?? '')
          .where((String id) => id.isNotEmpty)
          .toSet();
    }

    final Set<String> activeIds = idsFor(active);
    final Set<String> pendingIds = idsFor(pending?['requestedLocalities']);
    String localityState(Map<String, dynamic> locality) {
      final String? state = locality['state']?.toString();
      if (const <String>{'active', 'pending', 'requestable'}.contains(state)) {
        return state!;
      }
      final String id = _id(locality);
      if (activeIds.contains(id)) return 'active';
      if (pendingIds.contains(id)) return 'pending';
      return 'requestable';
    }

    final int zoneRequestableCount = zones.fold<int>(0, (int count, dynamic rawZone) {
      if (rawZone is! Map) return count;
      final List<dynamic> localities =
          (rawZone['localities'] as List?) ?? const <dynamic>[];
      return count + localities.where((dynamic locality) {
        return locality is Map &&
            localityState(Map<String, dynamic>.from(locality)) == 'requestable';
      }).length;
    });
    final int zoneActiveCount = zones.fold<int>(0, (int count, dynamic rawZone) {
      if (rawZone is! Map) return count;
      final List<dynamic> localities =
          (rawZone['localities'] as List?) ?? const <dynamic>[];
      return count + localities.where((dynamic locality) {
        return locality is Map &&
            localityState(Map<String, dynamic>.from(locality)) == 'active';
      }).length;
    });
    final int zonePendingCount = zones.fold<int>(0, (int count, dynamic rawZone) {
      if (rawZone is! Map) return count;
      final List<dynamic> localities =
          (rawZone['localities'] as List?) ?? const <dynamic>[];
      return count + localities.where((dynamic locality) {
        return locality is Map &&
            localityState(Map<String, dynamic>.from(locality)) == 'pending';
      }).length;
    });
    final int zoneLocalityCount = zones.fold<int>(0, (int count, dynamic rawZone) {
      if (rawZone is! Map) return count;
      final List<dynamic> localities =
          (rawZone['localities'] as List?) ?? const <dynamic>[];
      return count + localities.length;
    });
    final int availableCount = zones.isNotEmpty
        ? zoneRequestableCount
        : nearby.length;
    final bool hasPublishedZone = eligibleZone != null || zones.isNotEmpty;
    final bool canRequest =
        hasPublishedZone && pending == null && availableCount > 0;
    final String? requestDisabledReason = pending != null
        ? 'A locality request is already waiting for admin review.'
        : _submitting
        ? 'Your request is being submitted.'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery area')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _LoadError(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            city['name']?.toString() ?? 'Outlet city',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your outlet\'s published delivery zone groups the localities '
                            'you can request. Admin approval activates each locality '
                            'for customer delivery.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (eligibleZone == null)
                    const _NoticeCard(
                      icon: Icons.map_outlined,
                      message:
                          'Your base locality is not in an active published delivery zone yet. Ask the platform admin to assign it to a zone.',
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Active delivery localities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    const _NoticeCard(
                      icon: Icons.info_outline,
                      message:
                          'No approved delivery localities are configured yet.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: active
                          .map(
                            (dynamic item) => Chip(
                              avatar: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(_name(item)),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  if (pending != null)
                    _NoticeCard(
                      icon: Icons.hourglass_top,
                      message:
                          'Your request for ${_localityNames(pending['requestedLocalities'])} is waiting for platform review. New localities are not active until approved.',
                    )
                  else if (latest?['status'] == 'rejected')
                    _NoticeCard(
                      icon: Icons.info_outline,
                      message: _requestOutcome(latest!),
                    ),
                  if (latest?['status'] == 'partially_approved')
                    _NoticeCard(
                      icon: Icons.fact_check_outlined,
                      message: _requestOutcome(latest!),
                    ),
                  if (pending != null && _hasReviewedLocalities(latest))
                    _NoticeCard(
                      icon: Icons.fact_check_outlined,
                      message: _requestOutcome(latest!),
                    ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Available localities',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text('$availableCount requestable'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasPublishedZone && availableCount == 0)
                    _NoticeCard(
                      icon: Icons.map_outlined,
                      message: zoneLocalityCount == 0
                          ? 'This zone has no active localities configured.'
                          : 'This zone has $zoneLocalityCount localities: $zoneActiveCount active and $zonePendingCount pending review. No others are currently available to request.',
                    )
                  else if (zones.isEmpty && eligibleZone != null)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: nearby.map((dynamic raw) {
                          final Map<String, dynamic> locality =
                              Map<String, dynamic>.from(raw as Map);
                          final String id = _id(locality);
                          return CheckboxListTile(
                            value: _selected.contains(id),
                            onChanged:
                                canRequest && !_submitting && id.isNotEmpty
                                ? (bool? selected) => setState(() {
                                    if (selected == true) {
                                      _selected.add(id);
                                    } else {
                                      _selected.remove(id);
                                    }
                                  })
                                : null,
                            title: Text(_name(locality)),
                            subtitle: const Text('In your outlet\'s delivery zone · Select to request'),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                  ...zones.map((dynamic rawZone) {
                    final Map<String, dynamic> zone =
                        Map<String, dynamic>.from(rawZone as Map);
                    final List<dynamic> localities =
                        (zone['localities'] as List?) ?? const <dynamic>[];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.map_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    zone['name']?.toString() ?? 'Delivery zone',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                Text('${localities.length} localities'),
                              ],
                            ),
                          ),
                          ...localities.map(
                            (dynamic rawLocality) {
                              final Map<String, dynamic> locality =
                                  Map<String, dynamic>.from(rawLocality as Map);
                              return _localityTile(
                                <String, dynamic>{
                                  ...locality,
                                  'state': localityState(locality),
                                },
                                canRequest: canRequest,
                                disabledReason: requestDisabledReason,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  if (canRequest) ...<Widget>[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Note for the platform reviewer (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _selected.isEmpty || _submitting
                          ? null
                          : _submit,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _submitting
                            ? 'Sending request…'
                            : 'Request selected localities (${_selected.length})',
                      ),
                    ),
                  ] else if (pending == null && hasPublishedZone)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No locality in your delivery zone is available to request.',
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _localityNames(dynamic raw) {
    if (raw is! List || raw.isEmpty) return 'the selected localities';
    return raw.map(_name).join(', ');
  }

  Widget _localityTile(
    Map<String, dynamic> locality, {
    required bool canRequest,
    String? disabledReason,
  }) {
    final String id = _id(locality);
    final String state = locality['state']?.toString() ?? 'requestable';
    final String detail;
    final IconData icon;
    switch (state) {
      case 'active':
        detail = 'Already active for delivery';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        detail = 'Waiting for platform approval';
        icon = Icons.hourglass_top;
        break;
      default:
        detail = canRequest
            ? 'In your outlet\'s delivery zone · Select to request'
            : disabledReason ?? 'Not currently available to request';
        icon = Icons.add_location_alt_outlined;
    }
    if (state != 'requestable') {
      return ListTile(
        leading: Icon(icon),
        title: Text(_name(locality)),
        subtitle: Text(detail),
        dense: true,
      );
    }
    return CheckboxListTile(
      value: _selected.contains(id),
      onChanged: canRequest && !_submitting && id.isNotEmpty
          ? (bool? selected) => setState(() {
              if (selected == true) {
                _selected.add(id);
              } else {
                _selected.remove(id);
              }
            })
          : null,
      title: Text(_name(locality)),
      subtitle: Text(detail),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  String _requestOutcome(Map<String, dynamic> request) {
    final List<dynamic> reviews =
        (request['localityReviews'] as List?) ?? const <dynamic>[];
    if (reviews.isEmpty) {
      if (request['status'] == 'rejected') {
        return 'Your latest request was declined: ${request['reviewNote'] ?? 'You can submit another request.'}';
      }
      return 'Your request was partially approved.';
    }
    final List<String> outcomes = reviews.map((dynamic raw) {
      final Map<String, dynamic> review = Map<String, dynamic>.from(raw as Map);
      final String locality = _name(review['locality']);
      final String status = review['status']?.toString() ?? 'reviewed';
      final String note = review['reviewNote']?.toString().trim() ?? '';
      final String label = status == 'approved'
          ? 'approved'
          : status == 'rejected'
          ? 'declined'
          : status.replaceAll('_', ' ');
      return '$locality: $label${status == 'rejected' && note.isNotEmpty ? ' ($note)' : ''}';
    }).toList();
    return 'Coverage request review: ${outcomes.join(' · ')}';
  }

  bool _hasReviewedLocalities(Map<String, dynamic>? request) {
    final List<dynamic> reviews =
        (request?['localityReviews'] as List?) ?? const <dynamic>[];
    return reviews.any((dynamic raw) {
      if (raw is! Map) return false;
      final String status = raw['status']?.toString() ?? 'pending';
      return status != 'pending';
    });
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
