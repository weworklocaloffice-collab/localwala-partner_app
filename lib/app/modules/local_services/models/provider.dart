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

/// Provider profile + onboarding state. `bookable` is separate from `status`:
/// approved but incomplete setup is not bookable (server decides).
class LsProvider {
  final String id;
  final String businessName;
  final String businessAddress;
  final String providerType;
  final String contactName;
  final String contactPhone;
  final String gstin;
  final String stateCode;
  final String status;
  final bool bookable;

  const LsProvider({
    required this.id,
    required this.businessName,
    required this.businessAddress,
    required this.providerType,
    required this.status,
    required this.bookable,
    this.contactName = '',
    this.contactPhone = '',
    this.gstin = '',
    this.stateCode = '',
  });

  factory LsProvider.fromJson(Map<String, dynamic> json) => LsProvider(
    id: '${json['_id'] ?? json['id'] ?? ''}',
    businessName: '${json['businessName'] ?? ''}',
    businessAddress: '${json['businessAddress'] ?? ''}',
    providerType: '${json['providerType'] ?? ''}',
    status: '${json['status'] ?? ''}',
    bookable: json['bookable'] == true,
    contactName: '${json['contactName'] ?? ''}',
    contactPhone: '${json['contactPhone'] ?? ''}',
    gstin: '${json['gstin'] ?? ''}',
    stateCode: '${json['stateCode'] ?? ''}',
  );
}

/// Provider offering (provider x service price row).
class LsOffering {
  final String id;
  final String serviceId;
  final String serviceName;
  final String variantId;
  final String variantName;
  final String image;
  final double price;
  final int durationMinutes;
  final String status;

  const LsOffering({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.variantId,
    required this.variantName,
    required this.image,
    required this.price,
    required this.durationMinutes,
    required this.status,
  });

  factory LsOffering.fromJson(Map<String, dynamic> json) {
    final dynamic service = json['service'];
    final dynamic variant = json['variant'];
    final Map<String, dynamic> serviceMap = service is Map<String, dynamic>
        ? service
        : <String, dynamic>{};
    final Map<String, dynamic> variantMap = variant is Map<String, dynamic>
        ? variant
        : <String, dynamic>{};
    return LsOffering(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      serviceId: '${serviceMap['_id'] ?? service ?? ''}',
      serviceName: '${serviceMap['name'] ?? ''}',
      variantId: '${variantMap['_id'] ?? variant ?? ''}',
      variantName: '${variantMap['name'] ?? ''}',
      image: '${json['image'] ?? ''}',
      price: _asDouble(json['price']),
      durationMinutes: _asInt(json['durationMinutes']),
      status: '${json['status'] ?? ''}',
    );
  }
}

class LsCatalogueService {
  final String id;
  final String key;
  final String name;
  final String category;
  final String categoryKey;
  final String pricingMode;
  final String bookingMode;
  final int baseDurationMinutes;
  final double? minPrice;
  final double? maxPrice;

  const LsCatalogueService({
    required this.id,
    required this.key,
    required this.name,
    this.category = '',
    this.categoryKey = '',
    required this.pricingMode,
    required this.bookingMode,
    required this.baseDurationMinutes,
    this.minPrice,
    this.maxPrice,
  });

  factory LsCatalogueService.fromJson(Map<String, dynamic> json) =>
      LsCatalogueService(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        key: '${json['key'] ?? ''}',
        name: '${json['name'] ?? ''}',
        category: '${json['category'] ?? ''}',
        categoryKey: '${json['categoryKey'] ?? ''}',
        pricingMode: '${json['pricingMode'] ?? ''}',
        bookingMode: '${json['bookingMode'] ?? ''}',
        baseDurationMinutes: _asInt(json['baseDurationMinutes']),
        minPrice: (json['minPrice'] as num?)?.toDouble(),
        maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      );
}

class LsCatalogueCategory {
  final String id;
  final String key;
  final String name;
  final String parent;

  const LsCatalogueCategory({
    required this.id,
    required this.key,
    required this.name,
    this.parent = '',
  });

  factory LsCatalogueCategory.fromJson(Map<String, dynamic> json) =>
      LsCatalogueCategory(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        key: '${json['key'] ?? ''}',
        name: '${json['name'] ?? ''}',
        parent: '${json['parent'] ?? ''}',
      );
}

class LsCatalogueVariant {
  final String id;
  final String name;
  final int durationMinutes;
  final double basePrice;

  const LsCatalogueVariant({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.basePrice,
  });

  factory LsCatalogueVariant.fromJson(Map<String, dynamic> json) =>
      LsCatalogueVariant(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        durationMinutes: _asInt(json['durationMinutes']),
        basePrice: _asDouble(json['price'] ?? json['basePrice']),
      );
}

class LsCatalogueAddon {
  final String id;
  final String name;
  final double price;
  final String unit;

  const LsCatalogueAddon({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
  });

  factory LsCatalogueAddon.fromJson(Map<String, dynamic> json) =>
      LsCatalogueAddon(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        price: _asDouble(json['price']),
        unit: '${json['unit'] ?? 'flat'}',
      );
}

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
