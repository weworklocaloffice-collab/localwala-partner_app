/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/profile/bloc/vendor_profile_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Profile: own record, verification status, submit-for-review.
class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorProfileBloc>(
      create: (_) => VendorProfileBloc()..add(const VendorProfileLoadRequested()),
      child: BlocBuilder<VendorProfileBloc, VendorProfileState>(
        builder: (BuildContext context, VendorProfileState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavProfile)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorProfileStatus.initial:
                  case VendorProfileStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorProfileStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            state.message.isNotEmpty ? state.message : l10n.somethingWentWrong,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorProfileBloc>()
                                .add(const VendorProfileRefreshed()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorProfileStatus.loaded:
                    return _ProfileBody(vendor: state.vendor, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.vendor, required this.l10n});

  final Map<String, dynamic> vendor;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final String verification = vendor['verificationStatus']?.toString() ?? '—';
    final bool canSubmit = verification == 'DRAFT' ||
        verification == 'CHANGES_REQUIRED' ||
        verification == 'REJECTED';

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorProfileBloc>().add(const VendorProfileRefreshed()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    vendor['name']?.toString() ?? '—',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor['mobile']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.realEstateProfileVerification}: $verification',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
                  ),
                  if ((vendor['verificationReason']?.toString() ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      vendor['verificationReason'].toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
                  ],
                ],
              ),
            ),
            if (canSubmit) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context
                    .read<VendorProfileBloc>()
                    .add(const VendorProfileSubmitRequested()),
                child: Text(l10n.realEstateProfileSubmit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
