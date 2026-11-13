/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Notices for the signed-in account.
///
/// Backed by `GET /notification/list`. The endpoint takes no user id: the server
/// reads the reader from the token, so there is nothing here that could show
/// someone else's notices.
///
/// Unread notices are shown with a marker rather than in a separate tab. A
/// partner checking "did that order come in" wants one list in recency order,
/// and a filter chip would make them tap before they could read.
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final PartnerRepository _repository = PartnerRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = const <dynamic>[];
  int _unreadCount = 0;
  bool _unreadOnly = false;
  bool _marking = false;

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

    final DioApiResponse response = await _repository.notifications(
      unreadOnly: _unreadOnly,
    );

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load notifications.';
      });
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _notifications = (body['notifications'] as List?) ?? const <dynamic>[];
      _unreadCount = (body['unreadCount'] as num?)?.toInt() ?? 0;
    });
  }

  /// Marks everything read, then reloads so the markers clear.
  Future<void> _markAllRead() async {
    setState(() => _marking = true);
    await _repository.markNotificationsRead();
    if (!mounted) return;
    setState(() => _marking = false);
    await _load();
  }

  /// An icon per notice kind, so the list is scannable without reading every line.
  IconData _icon(String kind) {
    switch (kind) {
      case 'order_placed':
        return Icons.receipt_long_outlined;
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'run_dispatched':
        return Icons.pedal_bike_outlined;
      case 'stop_completed':
        return Icons.task_alt_outlined;
      case 'low_stock':
        return Icons.inventory_2_outlined;
      case 'fssai_expiry':
        return Icons.verified_user_outlined;
      case 'settlement_paid':
        return Icons.account_balance_outlined;
      case 'payout_recorded':
        return Icons.payments_outlined;
      case 'subscription_paused':
        return Icons.event_busy_outlined;
      case 'compliance_failed':
        return Icons.gpp_maybe_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  /// A relative day, which is what a person actually wants; an absolute
  /// timestamp for anything older than a week.
  String _when(String? iso) {
    if (iso == null) return '';
    final DateTime? then = DateTime.tryParse(iso);
    if (then == null) return '';
    final Duration gap = DateTime.now().difference(then);

    if (gap.inMinutes < 1) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
    if (gap.inHours < 24) return '${gap.inHours}h ago';
    if (gap.inDays == 1) return 'yesterday';
    if (gap.inDays < 7) return '${gap.inDays}d ago';

    return '${then.day}/${then.month.toString().padLeft(2, '0')}/${then.year}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    return SectionListScreen(
      title: l10n.navHome,
      icon: Icons.notifications_none_outlined,
      onRefresh: _load,
      actions: <Widget>[
        if (_unreadCount > 0)
          TextButton(
            onPressed: _marking ? null : _markAllRead,
            child: _marking
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
      ],
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Text(
                  _unreadCount == 0
                      ? 'No unread notifications'
                      : '$_unreadCount unread',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                FilterChip(
                  label: const Text('Unread only'),
                  selected: _unreadOnly,
                  onSelected: (bool value) {
                    setState(() => _unreadOnly = value);
                    _load();
                  },
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: 'Notifications unavailable',
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_notifications.isEmpty)
          EmptyState(
            title: _unreadOnly ? 'Nothing unread' : 'No notifications',
            message: _unreadOnly
                ? 'Everything here has been read.'
                : 'Order arrivals, dispatch, expiring licences and payouts appear here.',
            icon: Icons.notifications_none_outlined,
          )
        else
          Card(
            child: Column(
              children: _notifications.map((dynamic raw) {
                final Map<String, dynamic> notice =
                    Map<String, dynamic>.from(raw as Map);
                final bool unread = notice['readAt'] == null;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primary.withValues(alpha: unread ? 0.18 : 0.08),
                    child: Icon(_icon(notice['kind']?.toString() ?? ''), color: theme.primary),
                  ),
                  title: Text(
                    notice['title']?.toString() ?? '',
                    style: unread
                        ? Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(notice['content']?.toString() ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(_when(notice['createdAt']?.toString())),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}