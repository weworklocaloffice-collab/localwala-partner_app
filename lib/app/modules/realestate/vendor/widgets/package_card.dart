/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Listing package card: name, price, listing count, duration, features.
///
/// The buy action arrives with the checkout screen — until then the card
/// renders without a button ([onBuy] null), never a dead one.
class VendorPackageCard extends StatelessWidget {
  const VendorPackageCard({super.key, required this.package, this.onBuy});

  final RealEstatePackageModel package;

  /// Opens checkout for this package. Null while the card is display-only.
  final ValueChanged<RealEstatePackageModel>? onBuy;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final String countText =
        package.listingCount == null ? l10n.realEstatePackagesUnlimited : '${package.listingCount} listings';
    final String durationText =
        package.durationDays != null ? '${package.durationDays} days' : '';

    return Material(
      color: theme.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: package.recommended ? theme.primary : theme.divider,
            width: package.recommended ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    package.name ?? package.code ?? '—',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (package.recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.realEstatePackagesPopular,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              package.price != null ? '₹${formatIndianPrice(package.price!)}' : '—',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: theme.titleText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              durationText.isNotEmpty ? '$countText · $durationText' : countText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
            ),
            if ((package.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                package.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
              ),
            ],
            if (package.features.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              for (final dynamic feature in package.features.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check, size: 14, color: theme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          feature.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (onBuy != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onBuy!(package),
                child: Text(l10n.realEstatePackagesBuy),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
