/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/vendor/nav_config.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// Vendor "More" menu (plan §11.1): the second-level destinations that
/// do not fit the bottom nav — customers, packages, payments, documents,
/// analytics, commissions, support, profile.
///
/// Renders from [vendorMoreItems]; each row pushes its destination.
/// Unregistered features are absent, never dead rows.
class VendorMoreScreen extends StatelessWidget {
  const VendorMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vendorMoreItems.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final VendorMoreItem item = vendorMoreItems[index];
          return Material(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: item.build),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.divider),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(item.icon, color: theme.bodyText),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.titleText),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.bodyText),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
