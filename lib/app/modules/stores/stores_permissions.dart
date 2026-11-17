/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
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

/// The signed-in partner actor's role permissions, as the server declares them.
///
/// The server returns the role's raw rights (`orders.*`, `settlement.view`, ...) so
/// the app never re-implements the §6.23 matrix in Dart. The one rule repeated here is
/// the matcher itself: an exact right, a `head.*` wildcard, or a capability word
/// (`stock_adjust` satisfies `inventory.stock_adjust`) all grant. Owner-only rights
/// never appear in a non-owner's list, so no second owner check is needed.
///
/// This is ADVISORY gating only — it hides actions the actor cannot perform so the UI
/// does not offer dead buttons. Every route re-checks the same rights server-side.
class StoresPermissions {
  const StoresPermissions(this.rights);

  final List<String> rights;

  /// Nothing is known about the actor (pre-load, or a failed capabilities call).
  /// Treat as unrestricted and let the server refuse; hiding the whole app on a
  /// diagnostics call would be worse than a button that answers 403.
  static const StoresPermissions unknown = StoresPermissions(<String>['*']);

  factory StoresPermissions.fromCapabilities(Map<String, dynamic>? body) {
    final dynamic raw = body?['permissions'];
    if (raw is! List) return unknown;
    return StoresPermissions(
      raw.map((dynamic value) => '$value').toList(growable: false),
    );
  }

  bool can(String right) {
    if (rights.contains('*') || rights.contains(right)) return true;
    final int dot = right.indexOf('.');
    if (dot <= 0) return false;
    if (rights.contains('${right.substring(0, dot)}.*')) return true;
    return rights.contains(right.substring(dot + 1));
  }
}
