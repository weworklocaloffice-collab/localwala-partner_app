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
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/app/modules/local_services/partner/documents/documents_view.dart';
import 'package:partner/app/modules/local_services/partner/leads/leads_view.dart';
import 'package:partner/app/modules/local_services/partner/quotes/quotes_view.dart';
import 'package:partner/app/modules/local_services/partner/settlements/settlements_view.dart';
import 'package:partner/app/modules/local_services/partner/recurring/recurring_view.dart';
import 'package:partner/app/modules/local_services/partner/subscriptions/subscriptions_view.dart';
import 'package:partner/app/modules/local_services/partner/staff/staff_view.dart';
import 'package:partner/app/modules/local_services/partner/dashboard/dashboard_view.dart';
import 'package:partner/app/modules/local_services/partner/earnings/earnings_view.dart';
import 'package:partner/app/modules/local_services/partner/earnings/earnings_detail_view.dart';
import 'package:partner/app/modules/local_services/partner/growth/growth_view.dart';
import 'package:partner/app/modules/local_services/partner/jobs/booking_list_view.dart';
import 'package:partner/app/modules/local_services/partner/onboarding/onboarding_view.dart';
import 'package:partner/app/modules/local_services/partner/variants/variants_view.dart';
import 'package:partner/app/modules/local_services/partner/addons/addons_view.dart';
import 'package:partner/app/modules/local_services/partner/availability/availability_view.dart';
import 'package:partner/app/modules/local_services/partner/areas/areas_view.dart';
import 'package:partner/app/modules/local_services/partner/policies/policies_view.dart';
import 'package:partner/app/modules/local_services/partner/reviews/reviews_view.dart';
import 'package:partner/app/modules/local_services/partner/support/support_view.dart';
import 'package:partner/app/modules/local_services/partner/marketing/marketing_view.dart';
import 'package:partner/app/modules/local_services/partner/catalogue/offerings_view.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Partner nav tree for the Local Services vertical.
///
/// Starts with jobs — the provider's daily surface — and grows tab by tab.
/// Tabs are added here, never in `app_shell.dart`.
class LocalServicesPartnerShellScreen extends StatefulWidget {
  const LocalServicesPartnerShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  @override
  State<LocalServicesPartnerShellScreen> createState() =>
      _LocalServicesPartnerShellScreenState();
}

class _LocalServicesPartnerShellScreenState
    extends State<LocalServicesPartnerShellScreen> {
  final LocalServicesProviderRepository _providerRepository =
      LocalServicesProviderRepository();

  int _index = 0;
  bool _checkingProvider = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkProvider();
  }

  Future<void> _checkProvider() async {
    final DioApiResponse response = await _providerRepository.myProvider();
    bool needsOnboarding =
        response.statusCode == 404 ||
        response.errorType == NetErrorType.notFound;
    if (!needsOnboarding && response.statusCode == 200) {
      final dynamic body = decodeBody(response);
      final dynamic provider = body is Map ? body['provider'] : null;
      final String status = provider is Map
          ? (provider['status'] ?? '').toString()
          : '';
      needsOnboarding =
          status.isNotEmpty && status != 'ACTIVE' && status != 'APPROVED';
    }
    if (!mounted) return;
    setState(() {
      _checkingProvider = false;
      _needsOnboarding = needsOnboarding;
    });
  }

  Future<void> _openMore() async {
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  AppLocalizations.of(sheetContext)?.ls_more_entries ?? 'More',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _moreSectionHeader(sheetContext, 'Operations'),
              for (final _MoreEntry entry in _moreEntries.where((e) => <int>[5, 6, 7, 8, 9, 10].contains(e.index)))
                ListTile(
                  leading: Icon(entry.icon),
                  title: Text(_moreEntryLabel(sheetContext, entry)),
                  trailing:
                      _index == entry.index ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(sheetContext).pop(entry.index),
                ),
              _moreSectionHeader(sheetContext, 'Catalogue'),
              for (final _MoreEntry entry in _moreEntries.where((e) => <int>[11, 12, 13, 14].contains(e.index)))
                ListTile(
                  leading: Icon(entry.icon),
                  title: Text(_moreEntryLabel(sheetContext, entry)),
                  trailing:
                      _index == entry.index ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(sheetContext).pop(entry.index),
                ),
              _moreSectionHeader(sheetContext, 'Settings & more'),
              for (final _MoreEntry entry in _moreEntries.where((e) => <int>[15, 16, 17, 18, 19, 20, 21, 22].contains(e.index)))
                ListTile(
                  leading: Icon(entry.icon),
                  title: Text(_moreEntryLabel(sheetContext, entry)),
                  trailing:
                      _index == entry.index ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(sheetContext).pop(entry.index),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _index && mounted) {
      setState(() => _index = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProvider) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsOnboarding) {
      return Scaffold(
        body: SafeArea(
          child: OnboardingScreen(session: widget.gate.session),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
        // Not `const`: the list ends with a ProfileScreen built from `widget.gate.session`,
// which is not a compile-time constant.
        children: <Widget>[
          const DashboardScreen(),
          BookingListScreen(),
          OfferingsScreen(),
          AvailabilityScreen(),
          EarningsScreen(),
          EarningsDetailScreen(),
          GrowthScreen(),
          LeadsScreen(),
          QuotesScreen(),
          RecurringScreen(),
          SettlementsScreen(),
          StaffScreen(),
          DocumentsScreen(),
          VariantsScreen(),
          AddonsScreen(),
          OnboardingScreen(session: widget.gate.session),
          ProfileScreen(
            session: widget.gate.session ?? const UserSessionModel(id: ''),
          ),
          const SubscriptionsScreen(),
          const ServiceAreasScreen(),
          const PoliciesScreen(),
          const ReviewsScreen(),
          const SupportScreen(),
          const MarketingScreen(),
         ],
       ),
      ),
       bottomNavigationBar: NavigationBar(
        selectedIndex: _index <= 4 ? _index : 5,
        onDestinationSelected: (int i) {
          if (i == 5) {
            _openMore();
          } else {
            setState(() => _index = i);
          }
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: AppLocalizations.of(context)?.ls_nav_home ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.work_outline),
            label: AppLocalizations.of(context)?.ls_nav_jobs ?? 'Jobs',
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            label: AppLocalizations.of(context)?.ls_nav_catalogue ?? 'Catalogue',
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            label: AppLocalizations.of(context)?.ls_nav_hours ?? 'Hours',
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            label: AppLocalizations.of(context)?.ls_nav_earnings ?? 'Earnings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: AppLocalizations.of(context)?.ls_nav_more ?? 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry(this.index, this.icon, this.label);

  final int index;
  final IconData icon;
  final String label;
}

Widget _moreSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

String _moreEntryLabel(BuildContext context, _MoreEntry entry) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  switch (entry.index) {
    case 5:
      return l10n?.ls_more_statement ?? entry.label;
    case 6:
      return l10n?.ls_more_growth ?? entry.label;
    case 7:
      return l10n?.ls_more_leads ?? entry.label;
    case 8:
      return l10n?.ls_more_quotes ?? entry.label;
    case 9:
      return l10n?.ls_more_recurring ?? entry.label;
    case 10:
      return l10n?.ls_more_settlements ?? entry.label;
    case 11:
      return l10n?.ls_more_staff ?? entry.label;
    case 12:
      return l10n?.ls_more_documents ?? entry.label;
    case 13:
      return l10n?.ls_more_variants ?? entry.label;
    case 14:
      return l10n?.ls_more_addons ?? entry.label;
    case 15:
      return l10n?.ls_more_onboarding ?? entry.label;
    case 16:
      return l10n?.ls_more_account ?? entry.label;
    case 17:
      return l10n?.ls_more_subscriptions ?? entry.label;
    case 18:
      return l10n?.ls_more_areas ?? entry.label;
    case 19:
      return l10n?.ls_more_policies ?? entry.label;
    case 20:
      return l10n?.ls_more_reviews ?? entry.label;
    case 21:
      return l10n?.ls_more_support ?? entry.label;
    case 22:
      return l10n?.ls_more_marketing ?? entry.label;
    default:
      return entry.label;
  }
}

const List<_MoreEntry> _moreEntries = <_MoreEntry>[
  _MoreEntry(5, Icons.receipt_long_outlined, 'Statement'),
  _MoreEntry(6, Icons.trending_up_outlined, 'Growth'),
  _MoreEntry(7, Icons.list_outlined, 'Leads'),
  _MoreEntry(8, Icons.request_quote_outlined, 'Quotes'),
  _MoreEntry(9, Icons.autorenew_outlined, 'Recurring'),
  _MoreEntry(10, Icons.account_balance_outlined, 'Settlements'),
  _MoreEntry(11, Icons.person_outlined, 'Staff'),
  _MoreEntry(12, Icons.folder_outlined, 'Documents'),
  _MoreEntry(13, Icons.format_color_fill_outlined, 'Variants'),
  _MoreEntry(14, Icons.add_box_outlined, 'Addons'),
  _MoreEntry(15, Icons.badge_outlined, 'Onboarding'),
  _MoreEntry(16, Icons.account_circle_outlined, 'Account'),
  _MoreEntry(17, Icons.card_membership_outlined, 'Subscriptions'),
  _MoreEntry(18, Icons.map_outlined, 'Areas'),
  _MoreEntry(19, Icons.gavel_outlined, 'Policies'),
  _MoreEntry(20, Icons.rate_review_outlined, 'Reviews'),
  _MoreEntry(21, Icons.support_agent_outlined, 'Support'),
  _MoreEntry(22, Icons.campaign_outlined, 'Marketing'),
];