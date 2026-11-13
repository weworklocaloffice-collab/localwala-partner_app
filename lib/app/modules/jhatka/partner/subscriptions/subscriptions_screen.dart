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
import 'package:partner/app/modules/jhatka/partner/subscriptions/jhatka_subscriptions_repository.dart';
import 'package:partner/app/modules/jhatka/partner/subscriptions/subscription_create_screen.dart';
import 'package:partner/app/modules/jhatka/partner/subscriptions/subscription_detail_screen.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The subscription console: pause, resume, skip-next, cancel, and manual
/// occurrence generation.
///
/// A pause that follows repeated stock failures shows the consecutive-failure
/// count and the auto-pause flag, so the shop sees the subscription paused
/// itself rather than wondering why deliveries stopped. Generation is
/// idempotent per subscription+date — a retry replays, it never duplicates.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final JhatkaSubscriptionsRepository _repository =
      JhatkaSubscriptionsRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _subscriptions = const <dynamic>[];
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
    final DioApiResponse response = await _repository.subscriptions();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load subscriptions.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _subscriptions = (body['subscriptions'] as List?) ?? const <dynamic>[];
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

  /// Manual occurrence generation for a date.
  ///
  /// Idempotent per subscription+date — a retry replays, never duplicates. Offered
  /// here (not just in the detail screen) because the common case is "the cron missed
  /// it, raise today now", and burying that two taps deep is how it doesn't happen.
  Future<void> _generateSheet(String subscriptionId) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final String iso =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _act(
      'generate:$subscriptionId:$iso',
      () => _repository.generateOccurrence(
        subscriptionId: subscriptionId,
        occurrenceDate: iso,
      ),
    );
  }

  Future<void> _reasonSheet({
    required String title,
    required String subscriptionId,
    required Future<DioApiResponse> Function(String reason) call,
  }) async {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                    AppLocalizations.of(context)!.realEstateDetailConfirm,
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
    await _act('$title:$subscriptionId', () => call(text));
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.navSubscriptions,
      icon: Icons.repeat_outlined,
      onRefresh: _load,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () async {
              final bool? created = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const SubscriptionCreateScreen(),
                ),
              );
              if (created == true && mounted) await _load();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.jhatkaActionNewSubscription,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaSubscriptionsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_subscriptions.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaNoSubscriptions,
            message: 'Active subscriptions for this outlet appear here.',
            icon: Icons.repeat_outlined,
          )
        else
          Card(
            child: Column(
              children: _subscriptions.map(_subscriptionTile).toList(),
            ),
          ),
      ],
    );
  }

  Widget _subscriptionTile(dynamic raw) {
    final Map<String, dynamic> sub = Map<String, dynamic>.from(raw as Map);
    final String id = (sub['id'] ?? sub['_id'] ?? '').toString();
    final String status = (sub['status'] ?? '').toString();
    final int failures = ((sub['consecutiveStockFailures'] as num?) ?? 0)
        .toInt();
    final bool busy = _actingOn != null && _actingOn!.endsWith(id);
    return ExpansionTile(
      // Tapping the header opens full detail (occurrences with billing state,
      // event trail); the inline buttons stay for the quick moves.
      onExpansionChanged: (_) {},
      title: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SubscriptionDetailScreen(subscriptionId: id),
            ),
          );
        },
        child: Text('Subscription ${sub['subscriptionNo'] ?? '—'}'),
      ),
      subtitle: Text(
        '$status${failures > 0 ? ' · $failures stock failures' : ''}'
        '${sub['willAutoPause'] == true ? ' · will auto-pause' : ''}',
      ),
      trailing: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : StatusChip(
              label: status.isEmpty ? '—' : status,
              color: status == 'paused' ? AppColors.expirySoon : AppColors.grey,
            ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (status == 'active') ...<Widget>[
                OutlinedButton(
                  onPressed: () => _reasonSheet(
                    title: AppLocalizations.of(
                      context,
                    )!.jhatkaActionPauseSubscription,
                    subscriptionId: id,
                    call: (String reason) => _repository.pause(id, reason),
                  ),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionPause),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _act('skip:$id', () => _repository.skipNext(id)),
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionSkipNext,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _generateSheet(id),
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionGenerate,
                  ),
                ),
              ],
              if (status == 'paused')
                OutlinedButton(
                  onPressed: () =>
                      _act('resume:$id', () => _repository.resume(id)),
                  child: Text(AppLocalizations.of(context)!.jhatkaActionResume),
                ),
              if (status == 'active' || status == 'paused')
                OutlinedButton(
                  onPressed: () => _reasonSheet(
                    title: AppLocalizations.of(
                      context,
                    )!.jhatkaActionCancelSubscription,
                    subscriptionId: id,
                    call: (String reason) => _repository.cancel(id, reason),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.realEstateDetailCancel,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
