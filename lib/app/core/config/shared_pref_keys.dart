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

class SharedPreferencesKey {
  static PublicKeys publicKeys = const PublicKeys();
  static AuthKeys authKeys = const AuthKeys();
}

class PublicKeys {
  const PublicKeys();
  String get businessEmail => '_businessEmail';
  String get businessMobile => '_businessMobile';
  String get companyNameKey => '_companyName';
  String get currencySymbolKey => '_currencySymbol';
  String get currencySide => '_currencySide';
  String get mediaUrl => '_mediaUrl';
  String get defaultLanguage => '_defaultLanguage';
  String get defaultCountryCode => '_defaultCountryCode';
  String get isDark => '_isDark';
  String get googleOAuthClientId => '_googleOAuthClientId';
  String get googleOAuthServerId => '_googleOAuthServerId';
  String get socialGoogleSignIn => '_socialGoogleSignIn';
  String get socialFacebookSignIn => '_socialFacebookSignIn';
  String get appLogo => '_appLogo';

  //// Notification Keys ////
  String get notificationBell => '_notificationBell';
}

class AuthKeys {
  const AuthKeys();

  /// Full serialised `UserSessionModel`.
  String get session => '_dairySession';

  String get uid => '_dairyUid';
  String get authToken => '_dairyAuthToken';
  String get authRefreshToken => '_dairyAuthRefreshToken';
  String get locale => '_dairyLocale';

  //// Dual role keys ////
  /// Device-side shell preference. Deliberately not persisted server-side —
  /// see `API/src/modules/dairy/services/dairy.profile.service.js`.
  String get activeRole => '_dairyActiveRole';
  String get availableRoles => '_dairyAvailableRoles';

  //// Delivery agent keys ////
  String get dairyDriver => '_dairyDriverProfile';
  String get ownDeliveryPartner => '_dairyOwnDeliveryPartner';
  String get driverPayoutMode => '_dairyDriverPayoutMode';
  String get activeDairyOutlet => '_activeDairyOutlet';

  /// Keys cleared on logout.
  List<String> get sessionScoped => <String>[
    session,
    uid,
    authToken,
    authRefreshToken,
    activeRole,
    availableRoles,
    activeDairyOutlet,
  ];
}
