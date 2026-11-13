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

class ServerErrorModel {
  final int code;
  final String message;
  final String extra;

  const ServerErrorModel({
    this.code = 0,
    this.message = '',
    this.extra = '',
  });

  factory ServerErrorModel.fromJson(Map<String, dynamic> json) {
    return ServerErrorModel(
      code: int.tryParse(json['code']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      extra: json['extra']?.toString() ?? '',
    );
  }
}