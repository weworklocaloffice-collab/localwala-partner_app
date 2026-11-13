/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';

/// Status → chip color. Reviews and terminal states read at a glance;
/// everything unlisted falls back to grey rather than crashing on a new
/// state the server adds later.
///
/// Covers listing states, lead states and visit states — one chip for
/// every pipeline row.
const Map<String, Color> _statusColors = <String, Color>{
  'DRAFT': Colors.grey,
  'SUBMITTED': Colors.blue,
  'IN_REVIEW': Colors.blue,
  'CHANGES_REQUIRED': Colors.orange,
  'APPROVED': Colors.teal,
  'PUBLISHED': Colors.green,
  'SOLD': Colors.purple,
  'RENTED': Colors.purple,
  'SUSPENDED': Colors.red,
  'EXPIRED': Colors.red,
  'REJECTED': Colors.red,
  'ARCHIVED': Colors.grey,
  'NEW': Colors.blue,
  'CONTACTED': Colors.cyan,
  'VISIT_REQUESTED': Colors.orange,
  'VISIT_SCHEDULED': Colors.indigo,
  'VISIT_COMPLETED': Colors.green,
  'FOLLOW_UP': Colors.amber,
  'HOLD': Colors.purple,
  'SALE': Colors.green,
  'LOST': Colors.red,
  'ASSIGNED': Colors.blue,
  'ACCEPTED': Colors.teal,
  'CHECK_IN': Colors.orange,
  'IN_PROGRESS': Colors.indigo,
  'COMPLETED': Colors.green,
  'CANCELLED': Colors.grey,
  'PENDING': Colors.orange,
  'PENDING_PAYMENT': Colors.orange,
  'ACTIVE': Colors.green,
  'CONVERTED_TO_SALE': Colors.purple,
  'REFUND_PENDING': Colors.amber,
  'REFUNDED': Colors.grey,
  'ADJUSTED': Colors.grey,
  'VERIFIED': Colors.teal,
  'EARNED': Colors.green,
  'SETTLEMENT_CREATED': Colors.indigo,
  'PAID': Colors.green,
  'REVERSED': Colors.red,
};

/// Compact status chip for pipeline rows and detail headers.
///
/// Unknown states render grey with the raw wire value — a new server state
/// must never break the list.
class ListingStatusChip extends StatelessWidget {
  const ListingStatusChip({super.key, required this.status, this.availability});

  final String? status;
  final String? availability;

  @override
  Widget build(BuildContext context) {
    final String label = (status ?? '—').replaceAll('_', ' ');
    final Color color = _statusColors[status] ?? Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (availability == 'ON_HOLD') ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Text(
              'ON HOLD',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
