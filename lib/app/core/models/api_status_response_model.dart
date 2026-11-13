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

class ApiStatusResponseModel {
  final bool? success;
  final String? message;

  const ApiStatusResponseModel({this.success, this.message});

  factory ApiStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiStatusResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}