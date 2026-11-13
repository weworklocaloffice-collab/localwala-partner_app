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

/// Marketplace lead. Unqualified + unclaimed rows are the open board;
/// qualifying claims the lead (provider set server-side) and charges the
/// configured lead fee exactly once (re-qualify dedupes).
class LsLead {
  final String id;
  final String code;
  final String status;
  final bool qualified;
  final bool mine;

  const LsLead({
    required this.id,
    required this.code,
    required this.status,
    required this.qualified,
    required this.mine,
  });

  factory LsLead.fromJson(
    Map<String, dynamic> json, {
    String? myProviderId,
  }) {
    final String provider = '${json['provider'] ?? ''}';
    return LsLead(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      code: '${json['leadCode'] ?? ''}',
      status: '${json['status'] ?? ''}',
      qualified: json['qualified'] == true,
      mine: myProviderId != null &&
          myProviderId.isNotEmpty &&
          provider == myProviderId,
    );
  }
}
