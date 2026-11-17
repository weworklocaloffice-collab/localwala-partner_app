import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Provider home: today's jobs, action-needed count, earnings snapshot.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  int _today = 0;
  int _needAction = 0;
  Map<String, dynamic> _earnings = const <String, dynamic>{};
  // (removed unused queues field)
  List<Map<String, dynamic>> _recent = const <Map<String, dynamic>>[];

  static const List<String> _actionable = <String>[
    'PENDING_PROVIDER',
    'ACCEPTED',
    'CONFIRMED',
    'IN_PROGRESS',
  ];

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
      final List<DioApiResponse> results = await Future.wait(
        <Future<DioApiResponse>>[
          _repository.bookings(),
          _repository.revenueSummary(),
        ],
      );
        final Map<String, dynamic> bookingsBody = decodeBody(results[0]);
      final List<dynamic> raw =
          (bookingsBody['results'] ?? bookingsBody['data'] ?? [])
              as List<dynamic>;
      final DateTime now = DateTime.now();
      int today = 0;
      int needAction = 0;
      final List<Map<String, dynamic>> recent = <Map<String, dynamic>>[];
      for (final dynamic item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final String status = '${item['status'] ?? ''}';
        if (_actionable.contains(status)) needAction += 1;
        final dynamic when = item['scheduledAt'] ?? item['startAt'];
        final DateTime? dt = when == null ? null : DateTime.tryParse('$when');
        if (dt != null &&
            dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day) {
          today += 1;
        }
        if (recent.length < 5) recent.add(item);
      }
      setState(() {
        _today = today;
        _needAction = needAction;
        _earnings = decodeBody(results[1]);
        _recent = recent;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _money(dynamic v) {
    if (v == null) return '0';
    return '$v';
  }

  Widget _attentionCard(BuildContext context) {
    final List<Map<String, dynamic>> tiles = <Map<String, dynamic>>[];
    if (_needAction > 0) {
      tiles.add(<String, dynamic>{
        'icon': Icons.pending_actions_outlined,
        'title': 'Jobs needing action: $_needAction',
        'subtitle': 'Pending, accepted, confirmed or in-progress jobs.',
        'color': const Color(0xFFD97706),
      });
    }
    final List<Map<String, dynamic>> problemJobs = _recent
        .where((Map<String, dynamic> b) {
          final String s = '${b['status'] ?? ''}';
          return s == 'CANCELLED' || s == 'DISPUTED' || s == 'NO_SHOW';
        })
        .toList();
    if (problemJobs.isNotEmpty) {
      tiles.add(<String, dynamic>{
        'icon': Icons.report_problem_outlined,
        'title': 'Problem jobs: ${problemJobs.length}',
        'subtitle': 'Cancelled, disputed or no-show bookings.',
        'color': const Color(0xFFDC2626),
      });
    }
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.assignment_turned_in_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Needs attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (tiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${tiles.length}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (tiles.isNotEmpty)
              ...tiles.map((Map<String, dynamic> t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: (t['color'] as Color).withValues(alpha: 0.12),
                      child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
                    ),
                    title: Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                  ))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('No urgent operational issues found.')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.storefront_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Dashboard',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Your business at a glance',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _quickAction(context, 'Jobs', Icons.work_outline),
                    _quickAction(context, 'Catalogue', Icons.storefront_outlined),
                    _quickAction(context, 'Earnings', Icons.payments_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _attentionCard(context),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: <Widget>[
              LsKpiCard(
                label: l10n?.ls_todays_jobs ?? "Today's jobs",
                value: '$_today',
                icon: Icons.today_outlined,
                color: const Color(0xFF2563EB),
              ),
              LsKpiCard(
                label: l10n?.ls_need_action ?? 'Need action',
                value: '$_needAction',
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFFD97706),
              ),
              LsKpiCard(
                label: l10n?.ls_payable ?? 'Payable',
                value: '₹${_money(_earnings['providerPayable'])}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF16A34A),
              ),
              LsKpiCard(
                label: l10n?.ls_completed_value ?? 'Completed value',
                value: '₹${_money(_earnings['grossBookingValue'])}',
                icon: Icons.trending_up_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          LsSectionHeader(
            title: 'Recent jobs',
          ),
          if (_recent.isEmpty)
            const LsEmptyState(
              icon: Icons.work_outline,
              title: 'No jobs yet',
              subtitle: 'New bookings will appear here.',
            )
          else
            ..._recent.map((Map<String, dynamic> b) {
              final String status = '${b['status'] ?? ''}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    '${b['bookingCode'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${b['bookingMode'] ?? ''} · ₹${b['serviceValue'] ?? 0}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: LsStatusBadge(status: status),
                ),
              );
            }),
        ],
      ),
    );
  }
}
