/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/listing_status_chip.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// Vendor listing row: cover, status, title, code, price, address, counters.
///
/// Display-only for now — the detail screen registers next and adds the
/// navigation. Prices arrive in rupees (money-edges gate); `priceOnRequest`
/// listings never show a figure through any path.
class VendorPropertyCard extends StatelessWidget {
  const VendorPropertyCard({super.key, required this.property, this.onTap});

  final RealEstatePropertyModel property;

  /// Opens the listing detail. Null while the row is display-only.
  final VoidCallback? onTap;

  String? _coverUrl() {
    for (final Map<String, dynamic> item in property.media) {
      if ((item['type']?.toString() ?? 'IMAGE') == 'IMAGE') {
        final String? url = item['thumbUrl']?.toString() ?? item['url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final String? cover = _coverUrl();

    final String priceText;
    if (property.priceOnRequest) {
      priceText = 'Price on request';
    } else if (property.price != null) {
      priceText = '₹${formatIndianPrice(property.price!)}'
          '${property.pricePeriod == 'MONTH' ? '/mo' : ''}';
    } else {
      priceText = '—';
    }

    final String address = property.mapAddress?.isNotEmpty == true
        ? property.mapAddress!
        : (property.addressLine ?? '');

    return Material(
      color: theme.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.divider),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: cover != null
                      ? Image.network(
                          resolveMediaUrl(cover),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _coverFallback(theme),
                        )
                      : _coverFallback(theme),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: ListingStatusChip(
                    status: property.status,
                    availability: property.availability,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    property.title ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if ((property.propertyCode ?? '').isNotEmpty)
                    Text(
                      property.propertyCode!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (address.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${property.views} views · ${property.enquiries} enquiries · ${property.leads} leads',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _coverFallback(AppThemeData theme) {
    return Container(
      height: 140,
      width: double.infinity,
      color: theme.divider.withValues(alpha: 0.3),
      child: Icon(Icons.apartment_outlined, size: 48, color: theme.bodyText),
    );
  }
}
