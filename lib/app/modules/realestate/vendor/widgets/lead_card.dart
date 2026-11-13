/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/listing_status_chip.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// Vendor lead row: customer, property, code, source and status.
///
/// Customer and property arrive populated — never a second lookup per
/// row. Display-only for now; the lead detail screen adds navigation.
class VendorLeadCard extends StatelessWidget {
  const VendorLeadCard({super.key, required this.lead, this.onTap});

  final RealEstateLeadModel lead;

  /// Opens the lead detail. Null while the row is display-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final String customerName = lead.customer?.displayName ?? '—';
    final String initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return Material(
      color: theme.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.primary.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: theme.titleText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if ((lead.customer?.mobile ?? '').isNotEmpty)
                          Text(
                            lead.customer!.mobile!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                          ),
                      ],
                    ),
                  ),
                  ListingStatusChip(status: lead.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lead.property?.title ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.titleText),
              ),
              const SizedBox(height: 4),
              Text(
                '${lead.leadCode ?? ''} · ${lead.source ?? ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
