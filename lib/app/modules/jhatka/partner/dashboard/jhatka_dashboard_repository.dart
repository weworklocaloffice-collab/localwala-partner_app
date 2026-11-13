/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
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

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/jhatka/jhatka_endpoints.dart';

/// Outlet dashboard numbers.
///
/// ## UNITS — the one thing to get right here
///
/// `jhatka.analytics.service` returns **rupees**. It is the one Jhatka read that
/// converts at its own boundary rather than handing back raw paise, so this
/// repository deliberately does NOT run its values through `jhatka_money`'s paise
/// formatter. Formatting a rupee value as paise would show a day's takings as
/// 100x too small, which on a screen an owner checks against the till is the kind
/// of bug that ends with the app being distrusted.
///
/// The window is capped at 90 days server side; asking for more is a 400, not a
/// silent clamp, so this surface surfaces the error rather than hiding it.
class JhatkaDashboardRepository {
  JhatkaDashboardRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> analytics({String? from, String? to}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.outletAnalytics,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
  }
}
