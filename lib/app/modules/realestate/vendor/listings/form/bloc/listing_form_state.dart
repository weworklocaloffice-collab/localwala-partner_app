/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'listing_form_bloc.dart';

enum ListingFormStatus { initial, loading, ready, submitting, success, failure }

class ListingFormState {
  final ListingFormStatus status;
  final String message;

  /// Null for create; the edited listing's id otherwise.
  final String? propertyId;

  final List<RealEstateCategoryModel> categories;
  final RealEstateCategoryModel? selectedCategory;
  final List<RealEstateGeoOption> cities;
  final List<RealEstateGeoOption> localities;
  final String? selectedCityId;
  final String? selectedLocalityId;

  final Map<String, dynamic> specs;
  final Set<String> amenities;
  final List<String> mediaUrls;
  final int uploading;
  final double? lat;
  final double? lng;

  const ListingFormState({
    this.status = ListingFormStatus.initial,
    this.message = '',
    this.propertyId,
    this.categories = const <RealEstateCategoryModel>[],
    this.selectedCategory,
    this.cities = const <RealEstateGeoOption>[],
    this.localities = const <RealEstateGeoOption>[],
    this.selectedCityId,
    this.selectedLocalityId,
    this.specs = const <String, dynamic>{},
    this.amenities = const <String>{},
    this.mediaUrls = const <String>[],
    this.uploading = 0,
    this.lat,
    this.lng,
  });

  bool get isEdit => propertyId != null && propertyId!.isNotEmpty;

  bool get hasCoords => lat != null && lng != null;

  ListingFormState copyWith({
    ListingFormStatus? status,
    String? message,
    String? Function()? propertyId,
    List<RealEstateCategoryModel>? categories,
    RealEstateCategoryModel? Function()? selectedCategory,
    List<RealEstateGeoOption>? cities,
    List<RealEstateGeoOption>? localities,
    String? Function()? selectedCityId,
    String? Function()? selectedLocalityId,
    Map<String, dynamic>? specs,
    Set<String>? amenities,
    List<String>? mediaUrls,
    int? uploading,
    double? Function()? lat,
    double? Function()? lng,
  }) {
    return ListingFormState(
      status: status ?? this.status,
      message: message ?? this.message,
      propertyId: propertyId != null ? propertyId() : this.propertyId,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory != null ? selectedCategory() : this.selectedCategory,
      cities: cities ?? this.cities,
      localities: localities ?? this.localities,
      selectedCityId: selectedCityId != null ? selectedCityId() : this.selectedCityId,
      selectedLocalityId: selectedLocalityId != null ? selectedLocalityId() : this.selectedLocalityId,
      specs: specs ?? this.specs,
      amenities: amenities ?? this.amenities,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      uploading: uploading ?? this.uploading,
      lat: lat != null ? lat() : this.lat,
      lng: lng != null ? lng() : this.lng,
    );
  }
}
