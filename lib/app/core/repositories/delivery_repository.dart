/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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

import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/core/services/offline_can_scan_queue.dart';

/// Delivery-agent calls. Guarded server side by the `dairyDriver` rights.
///
/// Note the asymmetry with food delivery: a rider here does not accept offers.
/// A run is assigned, and the rider's job is to execute the manifest.
class DeliveryRepository {
  DeliveryRepository({
    AuthRepository? authRepository,
    OfflineCanScanQueue? queue,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _queue = queue ?? OfflineCanScanQueue();

  final AuthRepository _authRepository;
  final OfflineCanScanQueue _queue;

  Future<DioApiResponse> onboardingStatus() async {
    return ApiRequestService.makeRequest(
      DairyPartnerEndpoints.driverOnboardingStatus,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Fills a rider endpoint's path placeholders.
  ///
  /// Rider routes carry no rider id â€” the API reads it from the access token â€” so
  /// only entity ids such as `run` and `stop` are substituted here. A missing
  /// value throws from [DairyPartnerEndpoints.resolve] rather than building a URL
  /// containing a literal `{run}`, which would fail as an opaque 404.
  Future<String> _path(
    String template, [
    Map<String, String> values = const <String, String>{},
  ]) async {
    return DairyPartnerEndpoints.resolve(template, values);
  }

  //// Manifest ////

  Future<DioApiResponse> todayRun() async {
    return ApiRequestService.makeRequest(
      DairyPartnerEndpoints.driverRunToday,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> pingLocation(
    String runId,
    Map<String, dynamic>? location,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverRunPingLocation, <String, String>{
        'run': runId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'location': _locationText(location)},
    );
  }

  /// The rider's completed and past runs.
  ///
  /// The route is a GET and resolves the rider from the token; sending `driver`
  /// in a POST body (the previous shape) hit no route at all.
  Future<DioApiResponse> runHistory({
    int page = 1,
    int limit = ApiRequestService.pageSize,
    String? status,
    String? serviceDate,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (serviceDate != null) 'serviceDate': serviceDate,
    };

    return ApiRequestService.makeRequest(
      '${DairyPartnerEndpoints.driverRunHistory}'
      '?${Uri(queryParameters: query).query}',
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> runDetail(String runId) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverRunDetail, <String, String>{
        'run': runId,
      }),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Begins the run at the depot. Captures `cansLoaded` and
  /// `cansLoadedForReturn` before any stop is attempted.
  Future<DioApiResponse> startRun({
    required String runId,
    required int cansLoaded,
    required int cansLoadedForReturn,
    required Map<String, dynamic> location,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverRunStart, <String, String>{
        'run': runId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'cansLoaded': cansLoaded,
        'cansLoadedForReturn': cansLoadedForReturn,
        'location': _locationText(location),
      },
    );
  }

  /// Closes the run. The API rejects this while the can ledger is out of
  /// balance unless an explicit adjustment reason is supplied.
  Future<DioApiResponse> completeRun({
    required String runId,
    required int cansReturned,
    String? adjustmentReason,
    bool forceClose = false,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverRunComplete, <String, String>{
        'run': runId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'cansReturned': cansReturned,
        if (adjustmentReason != null) 'adjustmentReason': adjustmentReason,
        if (forceClose) 'forceClose': true,
      },
    );
  }

  //// Stops ////

  Future<DioApiResponse> stops(String runId) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverStopList, <String, String>{
        'run': runId,
      }),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> arriveStop(
    String stopId,
    Map<String, dynamic>? location,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverStopArrive, <String, String>{
        'stop': stopId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'location': _locationText(location)},
    );
  }

  Future<DioApiResponse> deliverStop({
    required String stopId,
    required int cansDelivered,
    required int emptyCansCollected,
    num amountCollected = 0,
    String? shortfallReason,
    String? clientRef,
    Map<String, dynamic>? proof,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverStopDeliver, <String, String>{
        'stop': stopId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'cansDelivered': cansDelivered,
        'emptyCansCollected': emptyCansCollected,
        'amountCollected': amountCollected,
        if (shortfallReason != null && shortfallReason.isNotEmpty)
          'shortfallReason': shortfallReason,
        if (clientRef != null && clientRef.isNotEmpty) 'clientRef': clientRef,
        if (proof != null) 'proof': proof,
      },
    );
  }

  /// The shared delivery validation currently accepts an optional `lat,lng`
  /// string. Keep that contract while accepting GeoJSON from the driver UI.
  String? _locationText(Map<String, dynamic>? point) {
    final List<dynamic>? coordinates = point?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.length < 2) return null;
    final double? longitude = double.tryParse(coordinates[0].toString());
    final double? latitude = double.tryParse(coordinates[1].toString());
    if (longitude == null ||
        latitude == null ||
        longitude < -180 ||
        longitude > 180 ||
        latitude < -90 ||
        latitude > 90) {
      return null;
    }
    return '$latitude,$longitude';
  }

  Future<DioApiResponse> skipStop(String stopId, String reason) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverStopSkip, <String, String>{
        'stop': stopId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  Future<DioApiResponse> failStop(String stopId, String reason) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverStopFail, <String, String>{
        'stop': stopId,
      }),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  //// Cans ////

  /// Queues a can event locally then flushes. Returns true when the scan
  /// reached the API, false when it is held in the outbox for later.
  Future<bool> queueCanScan(PendingCanScan scan) async {
    await _queue.enqueue(scan);
    return flushCanScans();
  }

  /// Replays the outbox in capture order. Acknowledged refs are dropped;
  /// anything left behind stays queued for the next connectivity window.
  Future<bool> flushCanScans() async {
    final List<PendingCanScan> scans = await _queue.pending();
    if (scans.isEmpty) return true;

    final List<String> acknowledged = <String>[];
    for (final PendingCanScan scan in scans) {
      final DioApiResponse response = await _submitScan(scan);
      if (response.errorType == NetErrorType.none) {
        acknowledged.add(scan.clientRef);
      } else {
        break;
      }
    }
    if (acknowledged.isNotEmpty) {
      await _queue.acknowledge(acknowledged);
    }
    return acknowledged.length == scans.length;
  }

  Future<DioApiResponse> _submitScan(PendingCanScan scan) async {
    final String template = switch (scan.type) {
      DairyCanScanType.pickup => DairyPartnerEndpoints.driverPickupScan,
      DairyCanScanType.issue => DairyPartnerEndpoints.driverCanIssueScan,
      DairyCanScanType.collect => DairyPartnerEndpoints.driverCanCollectScan,
      DairyCanScanType.returnToStore => DairyPartnerEndpoints.driverReturnScan,
    };
    return ApiRequestService.makeRequest(
      await _path(template),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'clientRef': scan.clientRef,
        'run': scan.runId,
        if (scan.stopId != null) 'stop': scan.stopId,
        if (scan.customerId != null) 'customer': scan.customerId,
        if (scan.orderId != null) 'order': scan.orderId,
        'canCodes': scan.canCodes,
        if (scan.note != null) 'note': scan.note,
      },
    );
  }

  Future<int> pendingScanCount() => _queue.count();

  Future<Map<DairyCanScanType, int>> localBalance(String runId) =>
      _queue.balanceForRun(runId);

  Future<DioApiResponse> depositSummary() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.driverCanDepositSummary),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Live can balance for a run, as recorded by the server.
  ///
  /// Distinct from [localBalance], which only counts scans still sitting in this
  /// device's outbox. The two are reconciled when the run is closed.
  Future<DioApiResponse> runBalance(String runId) async {
    return ApiRequestService.makeRequest(
      DairyPartnerEndpoints.resolve(
        DairyPartnerEndpoints.driverCanRunBalance,
        <String, String>{'run': runId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  //// Money ////

  /// Rider earnings for a window.
  ///
  /// The rider is resolved server-side from the token; neither call accepts an
  /// id. `from`/`to` must be query parameters: the API validates `req.query`,
  /// and `makeRequest` puts `body` in the request payload for GET too, so the
  /// window has to be appended to the path or it is silently ignored.
  Future<DioApiResponse> earnings({String? from, String? to}) async {
    final Map<String, String> query = <String, String>{
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    final String endpoint = query.isEmpty
        ? DairyPartnerEndpoints.driverEarnings
        : '${DairyPartnerEndpoints.driverEarnings}?${Uri(queryParameters: query).query}';

    return ApiRequestService.makeRequest(
      endpoint,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> cashInHand() async {
    return ApiRequestService.makeRequest(
      DairyPartnerEndpoints.driverCashInHand,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> depositCash(double amount, {String? reference}) async {
    return ApiRequestService.makeRequest(
      DairyPartnerEndpoints.driverCashDeposit,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'amount': amount,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
      },
    );
  }
}
