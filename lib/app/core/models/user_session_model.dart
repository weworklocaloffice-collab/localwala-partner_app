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

/// Roles this app can hold. Mirrors the role enums in `API/src/config/roles.js`.
enum DairyAppRole {
  /// Dairy store / commission partner / franchise operator.
  partner('dairyPartner', 'Partner'),

  /// Dairy route rider.
  driver('dairyDriver', 'Delivery'),

  /// Jhatka outlet operator.
  jhatkaPartner('jhatkaPartner', 'Jhatka Partner'),

  /// Jhatka outlet rider.
  jhatkaDriver('jhatkaDriver', 'Jhatka Rider'),

  /// Local Services provider.
  localServicesPartner('user', 'Local Services Partner'),

  /// Real Estate partner.
  realestatePartner('user', 'Real Estate Partner'),

  /// Store driver (store-owned delivery). Uses the Partner app driver shell (BR-05).
  storeDriver('storeDriver', 'Store Driver');

  const DairyAppRole(this.wire, this.label);

  final String wire;
  final String label;

  static DairyAppRole? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final DairyAppRole role in DairyAppRole.values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// Delivery agent source. Mirrors `DeliveryRun.agentMode`.
///
/// This app resolves an agent from exactly one of these two modes:
/// `ownFleet` is populated only when the business has
/// `Business.ownDeliveryPartner === true`, otherwise the agent comes from
/// the platform pool.
enum DairyAgentMode {
  ownFleet('own_fleet'),
  platformPool('platform_pool');

  const DairyAgentMode(this.wire);

  final String wire;

  static DairyAgentMode fromWire(String? value) {
    return value == 'own_fleet' ? DairyAgentMode.ownFleet : DairyAgentMode.platformPool;
  }
}

/// Resolved session for the logged in user.
///
/// A single session can hold [availableRoles] (an owner-operator is frequently
/// both partner and rider). [activeRole] decides which shell renders. The two
/// shells never blend their navigation trees.
class UserSessionModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? countryCode;
  final String? cover;

  /// Business / store the user operates. Null for a pure platform rider.
  final String? business;

  /// Raw role string from the API (`config/roles.js`).
  final String? role;

  final List<DairyAppRole> availableRoles;
  final DairyAppRole activeRole;

  /// Vertical (module) this session works in — `'dairy'`, `'realestate'`, …
  ///
  /// Empty until the account spans more than one vertical and the user
  /// picks one in `shell/vertical_picker/`. Dispatch falls back to the
  /// first registered vertical while it is empty, which is dairy.
  final String activeVertical;

  /// Verticals this session may enter. Defaults to dairy-only; the server
  /// extends the list once a second vertical has partner shells.
  final List<String> availableVerticals;

  /// Shells this session may enter inside the realestate vertical
  /// (`'vendor'`, `'executive'`). Dairy shells stay on [DairyAppRole];
  /// realestate shells are wire strings because no enum owns them yet.
  final List<String> availableRealEstateShells;

  /// Active realestate shell. Empty until picked; defaults to the first
  /// available shell, mirroring how [activeRole] defaults.
  final String activeRealEstateShell;

  final String? dairyDriverProfileId;
  final bool ownDeliveryPartner;
  final String? driverPayoutMode;

  const UserSessionModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email,
    this.mobile,
    this.countryCode,
    this.cover,
    this.business,
    this.role,
    this.availableRoles = const <DairyAppRole>[],
    this.activeRole = DairyAppRole.partner,
    this.activeVertical = '',
    this.availableVerticals = const <String>['dairy'],
    this.availableRealEstateShells = const <String>[],
    this.activeRealEstateShell = '',
    this.dairyDriverProfileId,
    this.ownDeliveryPartner = false,
    this.driverPayoutMode,
  });

  bool get isPartner =>
      activeRole == DairyAppRole.partner || activeRole == DairyAppRole.jhatkaPartner;

  bool get isDriver =>
      activeRole == DairyAppRole.driver || activeRole == DairyAppRole.jhatkaDriver;

  /// True when this session can switch shells. Owner-operators can.
  bool get canSwitchRole => availableRoles.length > 1;

  /// True when the vertical picker must be shown: the account spans more
  /// than one vertical and no choice has been persisted yet.
  bool get needsVerticalChoice => availableVerticals.length > 1 && activeVertical.isEmpty;

  /// Agent source for delivery runs. Only meaningful for a driver session.
  DairyAgentMode get agentMode =>
      ownDeliveryPartner ? DairyAgentMode.ownFleet : DairyAgentMode.platformPool;

  UserSessionModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? countryCode,
    String? cover,
    String? business,
    String? role,
    List<DairyAppRole>? availableRoles,
    DairyAppRole? activeRole,
    String? activeVertical,
    List<String>? availableVerticals,
    List<String>? availableRealEstateShells,
    String? activeRealEstateShell,
    String? dairyDriverProfileId,
    bool? ownDeliveryPartner,
    String? driverPayoutMode,
  }) {
    return UserSessionModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      countryCode: countryCode ?? this.countryCode,
      cover: cover ?? this.cover,
      business: business ?? this.business,
      role: role ?? this.role,
      availableRoles: availableRoles ?? this.availableRoles,
      activeRole: activeRole ?? this.activeRole,
      activeVertical: activeVertical ?? this.activeVertical,
      availableVerticals: availableVerticals ?? this.availableVerticals,
      availableRealEstateShells: availableRealEstateShells ?? this.availableRealEstateShells,
      activeRealEstateShell: activeRealEstateShell ?? this.activeRealEstateShell,
      dairyDriverProfileId: dairyDriverProfileId ?? this.dairyDriverProfileId,
      ownDeliveryPartner: ownDeliveryPartner ?? this.ownDeliveryPartner,
      driverPayoutMode: driverPayoutMode ?? this.driverPayoutMode,
    );
  }

  factory UserSessionModel.fromJson(Map<String, dynamic> json) {
    final List<DairyAppRole> roles = <DairyAppRole>[];
    final dynamic rawRoles = json['availableRoles'] ?? json['available_roles'];
    if (rawRoles is List) {
      for (final dynamic role in rawRoles) {
        final DairyAppRole? parsed = DairyAppRole.fromWire(role?.toString());
        if (parsed != null) roles.add(parsed);
      }
    }
    if (roles.isEmpty) {
      final DairyAppRole? fallback = DairyAppRole.fromWire(json['role']?.toString());
      if (fallback != null) roles.add(fallback);
    }

    final DairyAppRole requested =
        DairyAppRole.fromWire((json['activeRole'] ?? json['active_role'])?.toString()) ??
        (roles.isNotEmpty ? roles.first : DairyAppRole.partner);

    // An active role the session does not actually hold is not honoured,
    // otherwise a stale cached value could render the wrong shell.
    final DairyAppRole active = roles.contains(requested) ? requested : (roles.isNotEmpty ? roles.first : DairyAppRole.partner);

    // Verticals the server reports. Absent → dairy-only, which keeps a
    // pre-vertical server and every cached session working unchanged.
    final List<String> verticals = <String>[];
    final dynamic rawVerticals = json['availableVerticals'] ?? json['available_verticals'] ?? json['verticals'];
    if (rawVerticals is List) {
      for (final dynamic vertical in rawVerticals) {
        final String? id = vertical?.toString();
        if (id != null && id.isNotEmpty && !verticals.contains(id)) verticals.add(id);
      }
    }
    if (verticals.isEmpty) verticals.add('dairy');

    // An active vertical the session does not hold is not honoured — the
    // choice is unmade (empty) and the picker runs again.
    final String requestedVertical = (json['activeVertical'] ?? json['active_vertical'])?.toString() ?? '';
    final String activeVertical = verticals.contains(requestedVertical) ? requestedVertical : '';

    // Realestate shells the session may enter. Same unmade-choice rule as
    // roles and verticals: an unknown persisted pick degrades to the first
    // available shell, and no shells means no active shell.
    final List<String> shells = <String>[];
    final dynamic rawShells = json['availableRealEstateShells'];
    if (rawShells is List) {
      for (final dynamic shell in rawShells) {
        final String? id = shell?.toString();
        if (id != null && id.isNotEmpty && !shells.contains(id)) shells.add(id);
      }
    }
    final String requestedShell = json['activeRealEstateShell']?.toString() ?? '';
    final String activeShell = shells.contains(requestedShell)
        ? requestedShell
        : (shells.isNotEmpty ? shells.first : '');

    return UserSessionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? json['first_name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      countryCode: json['countryCode']?.toString() ?? json['country_code']?.toString(),
      cover: json['cover']?.toString(),
      business: (json['business'] is Map) ? (json['business']['_id']?.toString() ?? json['business']['id']?.toString()) : json['business']?.toString(),
      role: json['role']?.toString(),
      availableRoles: roles,
      activeRole: active,
      activeVertical: activeVertical,
      availableVerticals: verticals,
      availableRealEstateShells: shells,
      activeRealEstateShell: activeShell,
      dairyDriverProfileId: (json['dairyDriver'] is Map)
          ? (json['dairyDriver']['_id']?.toString() ?? json['dairyDriver']['id']?.toString())
          : json['dairyDriver']?.toString(),
      ownDeliveryPartner: json['ownDeliveryPartner'] == true || json['own_delivery_partner'] == true,
      driverPayoutMode: (json['driverPayoutMode'] ?? json['driver_payout_mode'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'countryCode': countryCode,
      'cover': cover,
      'business': business,
      'role': role,
      'availableRoles': availableRoles.map((DairyAppRole e) => e.wire).toList(),
      'activeRole': activeRole.wire,
      'activeVertical': activeVertical,
      'availableVerticals': availableVerticals,
      'availableRealEstateShells': availableRealEstateShells,
      'activeRealEstateShell': activeRealEstateShell,
      'dairyDriverProfileId': dairyDriverProfileId,
      'ownDeliveryPartner': ownDeliveryPartner,
      'driverPayoutMode': driverPayoutMode,
    };
  }
}