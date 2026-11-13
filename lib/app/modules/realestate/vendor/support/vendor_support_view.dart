/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Support (plan §11.3).
///
/// Two files by design: a contact + help-topics page with no bloc. There
/// is no shared support-chat surface in this app yet — when one lands,
/// this screen grows a chat entry instead of a second support screen.
class VendorSupportScreen extends StatelessWidget {
  const VendorSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    final List<Map<String, String>> topics = <Map<String, String>>[
      <String, String>{'t': l10n.realEstateSupportT1, 'b': l10n.realEstateSupportB1},
      <String, String>{'t': l10n.realEstateSupportT2, 'b': l10n.realEstateSupportB2},
      <String, String>{'t': l10n.realEstateSupportT3, 'b': l10n.realEstateSupportB3},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.realEstateNavSupport)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, String> topic = topics[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  topic['t']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: theme.titleText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic['b']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
