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

import 'dart:typed_data';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/local_services/local_services_endpoints.dart';

/// Transport failures throw the raw [DioApiResponse]; screens decode with
/// [decodeBody] and render `message`. No paise conversion here — money
/// arrives in rupees on every edge.
class LocalServicesProviderRepository {
  LocalServicesProviderRepository({AuthRepository? authRepository})
    : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  Future<DioApiResponse> _get(String url) async =>
      ApiRequestService.makeRequest(
        url,
        method: 'GET',
        token: await _auth.authToken(),
      );

  Future<DioApiResponse> _post(
    String url, [
    Map<String, dynamic>? body,
  ]) async => ApiRequestService.makeRequest(
    url,
    method: 'POST',
    token: await _auth.authToken(),
    body: body ?? <String, dynamic>{},
  );

  Future<DioApiResponse> _patch(String url, Map<String, dynamic> body) async =>
      ApiRequestService.makeRequest(
        url,
        method: 'PATCH',
        token: await _auth.authToken(),
        body: body,
      );

  //// Onboarding ////
  Future<DioApiResponse> register(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.register, payload);

  Future<DioApiResponse> myProvider() =>
      _get(LocalServicesPartnerEndpoints.myProvider);

  Future<DioApiResponse> updateProvider(
    String id,
    Map<String, dynamic> payload,
  ) => _patch(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.updateProvider,
      <String, String>{'id': id},
    ),
    payload,
  );

  Future<DioApiResponse> submitProvider(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.submitProvider,
      <String, String>{'id': id},
    ),
  );

  //// Catalogue ////
  Future<DioApiResponse> offerings() =>
      _get(LocalServicesPartnerEndpoints.offerings);

  Future<DioApiResponse> createOffering(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.offerings, payload);

  Future<DioApiResponse> updateOffering(
    String id,
    Map<String, dynamic> payload,
  ) => _patch(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.updateOffering,
      <String, String>{'id': id},
    ),
    payload,
  );

  Future<DioApiResponse> publicServices() =>
      _get(LocalServicesPartnerEndpoints.publicServices);

  Future<DioApiResponse> publicServiceDetail(String id) => _get(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.publicServiceDetail,
      <String, String>{'id': id},
    ),
  );

  Future<DioApiResponse> submitOffering(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.submitOffering,
      <String, String>{'id': id},
    ),
  );

  Future<DioApiResponse> uploadOfferingImage({
    required String filePath,
    required String filename,
  }) async => ApiRequestService.uploadFile(
    'v1/file/uploadImage/',
    filePath: filePath,
    filename: filename,
    token: await _auth.authToken(),
  );

  //// Jobs ////
  Future<DioApiResponse> bookings({String? status}) => _get(
    '${LocalServicesPartnerEndpoints.bookings}${status == null || status.isEmpty ? '' : '?status=$status'}',
  );

  Future<DioApiResponse> bookingDetail(String id) => _get(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.bookingDetail,
      <String, String>{'id': id},
    ),
  );

  Future<Uint8List?> invoicePdfBytes(String id) async =>
      ApiRequestService.downloadBytes(
        LocalServicesPartnerEndpoints.resolve(
          LocalServicesPartnerEndpoints.bookingInvoicePdf,
          <String, String>{'id': id},
        ),
        token: await _auth.authToken(),
      );

  Future<DioApiResponse> submitQuote(
    String bookingId,
    Map<String, dynamic> payload,
  ) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.bookingQuote,
      <String, String>{'id': bookingId},
    ),
    payload,
  );

  Future<DioApiResponse> transitionBooking(
    String id,
    String status, [
    Map<String, dynamic>? body,
  ]) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.bookingTransition,
      <String, String>{'id': id, 'status': status},
    ),
    body,
  );

  /// Both keys are always sent: an explicit `null` clears that side of the
  /// assignment server-side, which is different from omitting the key.
  Future<DioApiResponse> assignBooking(
    String id, {
    String? staff,
    String? resource,
  }) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.bookingAssign,
      <String, String>{'id': id},
    ),
    <String, dynamic>{'staff': staff, 'resource': resource},
  );

  Future<DioApiResponse> releaseAssignment(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.bookingRelease,
      <String, String>{'id': id},
    ),
  );

  Future<DioApiResponse> reviseQuote(
    String quoteId,
    Map<String, dynamic> payload,
  ) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.quoteRevise,
      <String, String>{'id': quoteId},
    ),
    payload,
  );

  //// Availability ////
  Future<DioApiResponse> staff() => _get(LocalServicesPartnerEndpoints.staff);

  Future<DioApiResponse> createStaff(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.staff, payload);

  Future<DioApiResponse> updateStaff(String id, Map<String, dynamic> payload) =>
      _patch(
        LocalServicesPartnerEndpoints.resolve(
          LocalServicesPartnerEndpoints.updateStaff,
          <String, String>{'id': id},
        ),
        payload,
      );

  Future<DioApiResponse> resources() =>
      _get(LocalServicesPartnerEndpoints.resources);

  Future<DioApiResponse> createResource(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.resources, payload);

  Future<DioApiResponse> updateResource(
    String id,
    Map<String, dynamic> payload,
  ) => _patch(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.updateResource,
      <String, String>{'id': id},
    ),
    payload,
  );

  //// Documents ////
  Future<DioApiResponse> documents() =>
      _get(LocalServicesPartnerEndpoints.documents);

  Future<DioApiResponse> uploadDocument(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.documents, payload);

  Future<DioApiResponse> uploadDocumentFile({
    required String filePath,
    required String filename,
  }) async => ApiRequestService.uploadFile(
    'v1/file/uploadImage/',
    filePath: filePath,
    filename: filename,
    token: await _auth.authToken(),
  );

  Future<DioApiResponse> saveAvailability(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.availability, payload);

  Future<DioApiResponse> coverage() =>
      _get(LocalServicesPartnerEndpoints.coverage);

  Future<DioApiResponse> saveCoverage(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.coverage, payload);

  //// Earnings ////
  Future<DioApiResponse> revenueSummary() =>
      _get(LocalServicesPartnerEndpoints.earnings);

  //// Leads (open board) ////
  Future<DioApiResponse> leads() => _get(LocalServicesPartnerEndpoints.leads);

  Future<DioApiResponse> qualifyLead(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.leadQualify,
      <String, String>{'id': id},
    ),
  );

  Future<DioApiResponse> invalidateLead(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.leadInvalidate,
      <String, String>{'id': id},
    ),
  );

  //// Provider management ////
  Future<DioApiResponse> saveBusinessDetails(
    String id,
    Map<String, dynamic> payload,
  ) => updateProvider(id, payload);

  Future<DioApiResponse> activateProvider(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.submitProvider,
      <String, String>{'id': id},
    ),
  );

  //// Recurring ////
  Future<DioApiResponse> occurrences() =>
      _get(LocalServicesPartnerEndpoints.occurrences);

  Future<DioApiResponse> recurring() => occurrences();

  Future<DioApiResponse> settlements({String? status}) => _get(
    status == null || status.isEmpty
        ? LocalServicesPartnerEndpoints.settlements
        : '${LocalServicesPartnerEndpoints.settlements}?status=$status',
  );

  Future<DioApiResponse> quotes({String? status}) => _get(
    status == null || status.isEmpty
        ? LocalServicesPartnerEndpoints.quotes
        : '${LocalServicesPartnerEndpoints.quotes}?status=$status',
  );

  //// Subscriptions ////
  Future<DioApiResponse> subscriptions() =>
      _get(LocalServicesPartnerEndpoints.subscriptions);

  Future<DioApiResponse> subscribePlan(String planId) => _post(
    LocalServicesPartnerEndpoints.subscriptions,
    <String, dynamic>{'plan': planId},
  );

  //// Marketing ////
  Future<DioApiResponse> marketingPackages() =>
      _get(LocalServicesPartnerEndpoints.marketingPackages);

  Future<DioApiResponse> marketingCampaigns() =>
      _get(LocalServicesPartnerEndpoints.marketingCampaigns);

  Future<DioApiResponse> createMarketingCampaign(
    Map<String, dynamic> payload,
  ) => _post(LocalServicesPartnerEndpoints.marketingCampaigns, payload);

  Future<DioApiResponse> payMarketingCampaign(String id) => _post(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.marketingCampaignPay,
      <String, String>{'id': id},
    ),
    <String, dynamic>{},
  );

  Future<DioApiResponse> updateMarketingCampaignStatus(
    String id,
    String action,
  ) => _patch(
    LocalServicesPartnerEndpoints.resolve(
      LocalServicesPartnerEndpoints.marketingCampaignStatus,
      <String, String>{'id': id},
    ),
    <String, dynamic>{'action': action},
  );

  //// Policies, reviews & support ////
  Future<DioApiResponse> policies() =>
      _get(LocalServicesPartnerEndpoints.policies);

  Future<DioApiResponse> reviews(String providerId) => _get(
    '${LocalServicesPartnerEndpoints.reviews}?provider=${Uri.encodeQueryComponent(providerId)}',
  );

  Future<DioApiResponse> complaints() =>
      _get(LocalServicesPartnerEndpoints.complaints);

  Future<DioApiResponse> createComplaint(Map<String, dynamic> payload) =>
      _post(LocalServicesPartnerEndpoints.complaints, payload);
}
