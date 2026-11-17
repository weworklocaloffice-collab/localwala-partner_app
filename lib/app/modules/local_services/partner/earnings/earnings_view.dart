import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const <String, dynamic>{};

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
      final DioApiResponse response = await _repository.revenueSummary();
      setState(() {
        _summary = decodeBody(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
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
    final List<Map<String, dynamic>> tiles = <Map<String, dynamic>>[
      <String, dynamic>{'label': l10n?.ls_gross_booking_value ?? 'Gross booking value', 'value': _summary['grossBookingValue'] ?? 0, 'icon': Icons.trending_up_outlined, 'color': const Color(0xFF2563EB)},
      <String, dynamic>{'label': l10n?.ls_booking_fees ?? 'Booking fees', 'value': _summary['bookingFees'] ?? 0, 'icon': Icons.receipt_long_outlined, 'color': const Color(0xFF0EA5E9)},
      <String, dynamic>{'label': l10n?.ls_commission ?? 'Commission', 'value': _summary['commission'] ?? 0, 'icon': Icons.percent_outlined, 'color': const Color(0xFF7C3AED)},
      <String, dynamic>{'label': l10n?.ls_provider_payable ?? 'Provider payable', 'value': _summary['providerPayable'] ?? 0, 'icon': Icons.account_balance_wallet_outlined, 'color': const Color(0xFF16A34A)},
      <String, dynamic>{'label': l10n?.ls_reversals ?? 'Reversals', 'value': _summary['reversals'] ?? 0, 'icon': Icons.undo_outlined, 'color': const Color(0xFFDC2626)},
    ];
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Earnings',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revenue summary (server-computed)',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...tiles.map((Map<String, dynamic> t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LsKpiCard(
                  label: t['label'] as String,
                  value: '₹${t['value']}',
                  icon: t['icon'] as IconData,
                  color: t['color'] as Color,
                ),
              )),
        ],
      ),
    );
  }
}
