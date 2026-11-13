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

/// Local Services partner endpoints, mounted at `/v1/local-services`.
///
/// Verified against `API/src/modules/local-services/index.js`. The provider
/// never appears here — the server derives it from the access token, so there
/// is nothing a client could change to reach another provider's bookings.
///
/// `{id}` placeholders resolve through [resolve], which throws rather than
/// issuing a request against a literal `{id}`.
class LocalServicesPartnerEndpoints {
  const LocalServicesPartnerEndpoints._();

  //// Onboarding ////
  static const String register = 'v1/local-services/partner/providers';
  static const String myProvider = 'v1/local-services/partner/providers';
  static const String updateProvider =
      'v1/local-services/partner/providers/{id}';
  static const String submitProvider =
      'v1/local-services/partner/providers/{id}/submit';

  //// Catalogue ////
  static const String offerings = 'v1/local-services/partner/offerings';
  static const String updateOffering =
      'v1/local-services/partner/offerings/{id}';
  static const String submitOffering =
      'v1/local-services/partner/offerings/{id}/submit';
  static const String publicServices = 'v1/local-services/public/services';
  static const String publicServiceDetail =
      'v1/local-services/public/services/{id}';

  //// Jobs (bookings) ////
  static const String bookings = 'v1/local-services/partner/bookings';
  static const String bookingDetail = 'v1/local-services/partner/bookings/{id}';
  static const String bookingInvoicePdf =
      'v1/local-services/partner/bookings/{id}/invoice/pdf';
  static const String bookingTransition =
      'v1/local-services/partner/bookings/{id}/{status}';
  static const String bookingAssign =
      'v1/local-services/partner/bookings/{id}/assign';
  static const String bookingQuote =
      'v1/local-services/partner/bookings/{id}/quote';
  static const String bookingRelease =
      'v1/local-services/partner/bookings/{id}/release';
  static const String quoteRevise =
      'v1/local-services/partner/quotes/{id}/revise';

  //// Leads (open board; qualify claims + charges lead fee) ////
  static const String leads = 'v1/local-services/leads?mine=false';
  static const String leadQualify = 'v1/local-services/leads/{id}/qualify';
  static const String leadInvalidate =
      'v1/local-services/leads/{id}/invalidate';

  static const String quotes = 'v1/local-services/partner/quotes';
  //// Recurring agreements ////
  static const String settlements = 'v1/local-services/partner/settlements';
  static const String recurringStatus =
      'v1/local-services/recurring/{id}/{status}';
  static const String occurrences = 'v1/local-services/occurrences';

  //// Staff, resources & availability ////
  static const String staff = 'v1/local-services/partner/staff';
  static const String updateStaff = 'v1/local-services/partner/staff/{id}';
  static const String resources = 'v1/local-services/partner/resources';
  static const String updateResource =
      'v1/local-services/partner/resources/{id}';
  static const String availability = 'v1/local-services/partner/availability';
  static const String coverage = 'v1/local-services/partner/coverage';

  //// Documents ////
  static const String documents = 'v1/local-services/partner/documents';

  //// Earnings (provider-scoped) ////
  static const String earnings = 'v1/local-services/partner/earnings';

  //// Subscriptions ////
  static const String subscriptions = 'v1/local-services/partner/subscriptions';

  //// Marketing ////
  static const String marketingPackages =
      'v1/local-services/partner/marketing/packages';
  static const String marketingCampaigns =
      'v1/local-services/partner/marketing/campaigns';
  static const String marketingCampaignPay =
      'v1/local-services/partner/marketing/campaigns/{id}/pay';
  static const String marketingCampaignStatus =
      'v1/local-services/partner/marketing/campaigns/{id}/status';

  //// Policies, reviews & support ////
  static const String policies = 'v1/local-services/partner/policies';
  static const String reviews = 'v1/local-services/customer/reviews';
  static const String complaints = 'v1/local-services/partner/complaints';

  static String resolve(String template, Map<String, String> values) {
    String out = template;
    final RegExp ph = RegExp(r'\{(\w+)\}');
    for (final RegExpMatch m in ph.allMatches(template)) {
      final String? v = values[m.group(1)];
      if (v == null || v.isEmpty) {
        throw ArgumentError('Missing path value for ${m.group(0)}');
      }
      out = out.replaceFirst(m.group(0)!, Uri.encodeComponent(v));
    }
    if (ph.hasMatch(out)) {
      throw ArgumentError('Unresolved placeholders in $out');
    }
    return out;
  }
}
