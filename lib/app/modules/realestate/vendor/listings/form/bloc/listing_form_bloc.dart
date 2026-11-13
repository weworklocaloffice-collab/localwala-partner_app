/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner/app/modules/realestate/models/geo_option.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_category.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'listing_form_event.dart';
part 'listing_form_state.dart';

/// Text basics owned by the view's controllers, handed over at submit.
///
/// Lives here (not in the event part file) because part files cannot hold
/// imports, and the events below need `XFile` and the property model.
class ListingFormBasics {
  final String title;
  final String? description;
  final String transactionType;
  final double? price;
  final bool priceOnRequest;
  final String? addressLine;
  final String? pincode;
  final String? mapAddress;
  final String? projectName;
  final String? builderName;

  const ListingFormBasics({
    required this.title,
    this.description,
    required this.transactionType,
    required this.price,
    this.priceOnRequest = false,
    this.addressLine,
    this.pincode,
    this.mapAddress,
    this.projectName,
    this.builderName,
  });
}

/// Loads categories + cities; with [property] set, prefills every field
/// for edit (category resolved through the snapshot key).
class ListingFormLoadRequested extends ListingFormEvent {
  final RealEstatePropertyModel? property;

  const ListingFormLoadRequested({this.property});
}

/// A picked image: uploaded first, the returned path appended on success.
class ListingFormMediaPicked extends ListingFormEvent {
  final XFile file;

  const ListingFormMediaPicked(this.file);
}

/// One field of a category's `specSchema.fields`.
///
/// Same `type` discriminator the backend validator, the Angular form
/// builder and the admin field editor switch on (NUMBER, STRING, TEXT,
/// ENUM, BOOLEAN, DATE). Unknown types render as text and validate as
/// strings — a new server type must never break the form.
class SpecFieldDescriptor {
  final String key;
  final String label;
  final String type;
  final bool required;
  final double? min;
  final double? max;
  final bool integer;
  final List<String> options;
  final int? minLength;
  final int? maxLength;

  const SpecFieldDescriptor({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.min,
    this.max,
    this.integer = false,
    this.options = const <String>[],
    this.minLength,
    this.maxLength,
  });

  static String humanize(String key) {
    final String spaced = key.replaceAllMapped(
      RegExp('([a-z0-9])([A-Z])'),
      (Match m) => '${m.group(1)} ${m.group(2)}',
    ).replaceAll(RegExp('[_-]+'), ' ');
    return spaced
        .split(' ')
        .where((String w) => w.isNotEmpty)
        .map((String w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  factory SpecFieldDescriptor.fromMap(Map<String, dynamic> map) {
    double? numOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? intOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final String key = (map['key'] ?? '').toString();
    return SpecFieldDescriptor(
      key: key,
      label: (map['label']?.toString().isNotEmpty == true)
          ? map['label'].toString()
          : humanize(key),
      type: (map['type']?.toString() ?? 'STRING').toUpperCase(),
      required: map['required'] == true,
      min: numOrNull(map['min']),
      max: numOrNull(map['max']),
      integer: map['integer'] == true,
      options: map['options'] is List
          ? (map['options'] as List).map((dynamic e) => e.toString()).toList()
          : const <String>[],
      minLength: intOrNull(map['minLength']),
      maxLength: intOrNull(map['maxLength']),
    );
  }
}

/// Descriptors of a category's spec schema, in order. Empty when the
/// category carries none — the specs section then stays hidden.
List<SpecFieldDescriptor> specFieldsOf(Map<String, dynamic>? specSchema) {
  final dynamic fields = specSchema == null ? null : specSchema['fields'];
  if (fields is! List) return const <SpecFieldDescriptor>[];
  return fields
      .whereType<Map>()
      .map((Map m) => SpecFieldDescriptor.fromMap(Map<String, dynamic>.from(m)))
      .where((SpecFieldDescriptor f) => f.key.isNotEmpty)
      .toList();
}

/// Client mirror of the server's spec validation. Returns the first
/// problem, or null when the value is acceptable. The server re-validates
/// everything — this only saves a round trip, never decides.
String? validateSpecValue(SpecFieldDescriptor field, dynamic value) {
  final bool missing =
      value == null || (value is String && value.trim().isEmpty);
  if (missing) {
    return field.required ? '${field.label} is required' : null;
  }
  switch (field.type) {
    case 'NUMBER':
      final double? n = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (n == null) return '${field.label} must be a number';
      if (field.min != null && n < field.min!) return '${field.label} must be at least ${field.min}';
      if (field.max != null && n > field.max!) return '${field.label} must be at most ${field.max}';
      if (field.integer && n.truncateToDouble() != n) return '${field.label} must be a whole number';
      return null;
    case 'ENUM':
      if (!field.options.contains(value.toString())) {
        return '${field.label} must be one of ${field.options.join(', ')}';
      }
      return null;
    case 'BOOLEAN':
      if (value is! bool) return '${field.label} must be yes or no';
      return null;
    case 'DATE':
      if (DateTime.tryParse(value.toString()) == null) return '${field.label} must be a valid date';
      return null;
    case 'STRING':
    case 'TEXT':
    default:
      final String s = value.toString();
      if (field.minLength != null && s.length < field.minLength!) {
        return '${field.label} must be at least ${field.minLength} characters';
      }
      if (field.maxLength != null && s.length > field.maxLength!) {
        return '${field.label} must be at most ${field.maxLength} characters';
      }
      return null;
  }
}

/// Builds the exact create/update payload. Keys are allow-listed by the
/// server (`.unknown(false)`), so nothing outside this map is sent —
/// notably no `state`/`country` (derived server-side) and no `customer`,
/// `status` or `vendor` (tenant from the token).
Map<String, dynamic> buildListingPayload({
  required String title,
  String? description,
  required String transactionType,
  required double price,
  required bool priceOnRequest,
  required String categoryId,
  String? addressLine,
  required String localityId,
  required String cityId,
  required double lng,
  required double lat,
  String? pincode,
  String? mapAddress,
  Map<String, dynamic> specs = const <String, dynamic>{},
  List<String> amenities = const <String>[],
  List<String> mediaUrls = const <String>[],
  String? projectName,
  String? builderName,
}) {
  return <String, dynamic>{
    'title': title,
    if (description != null && description.isNotEmpty) 'description': description,
    'transactionType': transactionType,
    'price': price,
    'priceOnRequest': priceOnRequest,
    'category': categoryId,
    'location': <String, dynamic>{
      if (addressLine != null && addressLine.isNotEmpty) 'addressLine': addressLine,
      'locality': localityId,
      'city': cityId,
      'coordinates': <double>[lng, lat],
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      if (mapAddress != null && mapAddress.isNotEmpty) 'mapAddress': mapAddress,
    },
    if (specs.isNotEmpty) 'specs': specs,
    if (amenities.isNotEmpty) 'amenities': amenities,
    if (mediaUrls.isNotEmpty)
      'media': <Map<String, dynamic>>[
        for (int i = 0; i < mediaUrls.length; i++)
          <String, dynamic>{'type': 'IMAGE', 'url': mediaUrls[i], 'sortOrder': i},
      ],
    if (projectName != null && projectName.isNotEmpty) 'projectName': projectName,
    if (builderName != null && builderName.isNotEmpty) 'builderName': builderName,
  };
}

/// First validation failure across the whole form, or null when the
/// payload can be built. Mirrors the server guards (title, transaction
/// type per category, price, category/city/locality/coordinates, specs,
/// media cap) so a fixable mistake never costs a round trip.
String? validateListingInput({
  required String title,
  required String transactionType,
  List<String>? allowedTransactions,
  required double? price,
  required String? categoryId,
  required String? cityId,
  required String? localityId,
  required double? lat,
  required double? lng,
  required List<SpecFieldDescriptor> specFields,
  required Map<String, dynamic> specs,
  required List<String> amenities,
  required List<String> mediaUrls,
  String? pincode,
}) {
  if (title.trim().length < 3) return 'Give the listing a title of at least 3 characters';
  if (title.trim().length > 200) return 'Keep the title under 200 characters';
  if (transactionType != 'BUY' && transactionType != 'RENT') {
    return 'Choose whether this listing is for sale or rent';
  }
  if (allowedTransactions != null &&
      allowedTransactions.isNotEmpty &&
      !allowedTransactions.contains(transactionType)) {
    return 'This category supports ${allowedTransactions.join(' and ')} only';
  }
  if (price == null || price < 0) return 'Enter a valid price (0 or more)';
  if (categoryId == null || categoryId.isEmpty) return 'Choose a category';
  if (cityId == null || cityId.isEmpty) return 'Choose a city';
  if (localityId == null || localityId.isEmpty) return 'Choose a locality';
  if (lat == null || lng == null) return 'Pin the location (use my location or enter coordinates)';
  if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    return 'Coordinates are out of range';
  }
  if (pincode != null && pincode.isNotEmpty && !RegExp(r'^[0-9]{4,10}$').hasMatch(pincode)) {
    return 'Pincode must be 4-10 digits';
  }
  for (final SpecFieldDescriptor field in specFields) {
    final String? problem = validateSpecValue(field, specs[field.key]);
    if (problem != null) return problem;
  }
  for (final String amenity in amenities) {
    if (amenity.length > 60) return 'Amenity names stay under 60 characters';
  }
  if (mediaUrls.length > 20) return 'At most 20 photos per listing';
  return null;
}

/// The listing form: category-driven specs, geo cascade, media upload.
///
/// Text basics live in the view's controllers; everything selectable or
/// asynchronous lives here. Submit validates client-side first (same
/// guards as the server), then creates — or updates when loaded with a
/// property. The form state survives every rebuild; only a successful
/// save pops the screen.
class ListingFormBloc extends Bloc<ListingFormEvent, ListingFormState> {
  ListingFormBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const ListingFormState()) {
    on<ListingFormLoadRequested>(_onListingFormLoadRequested);
    on<ListingFormCategorySelected>(_onListingFormCategorySelected);
    on<ListingFormCitySelected>(_onListingFormCitySelected);
    on<ListingFormLocalitySelected>(_onListingFormLocalitySelected);
    on<ListingFormCoordsChanged>(_onListingFormCoordsChanged);
    on<ListingFormSpecChanged>(_onListingFormSpecChanged);
    on<ListingFormAmenityToggled>(_onListingFormAmenityToggled);
    on<ListingFormMediaPicked>(_onListingFormMediaPicked);
    on<ListingFormMediaRemoved>(_onListingFormMediaRemoved);
    on<ListingFormSubmitted>(_onListingFormSubmitted);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _onListingFormLoadRequested(
    ListingFormLoadRequested event,
    Emitter<ListingFormState> emit,
  ) async {
    emit(state.copyWith(status: ListingFormStatus.loading, message: ''));
    try {
      final List<dynamic> loaded = await Future.wait(<Future<dynamic>>[
        _repository.categories(),
        _repository.cities(),
      ]);
      final List<RealEstateCategoryModel> categories = loaded[0] as List<RealEstateCategoryModel>;
      final List<RealEstateGeoOption> cities = loaded[1] as List<RealEstateGeoOption>;

      final RealEstatePropertyModel? property = event.property;
      if (property == null) {
        emit(state.copyWith(
          status: ListingFormStatus.ready,
          categories: categories,
          cities: cities,
        ));
        return;
      }

      // Edit: resolve the full category through the snapshot key, then the
      // geo cascade, then the saved values.
      RealEstateCategoryModel? full;
      final String? snapshotKey = property.categorySnapshot == null
          ? null
          : property.categorySnapshot!['key']?.toString();
      if (snapshotKey != null && snapshotKey.isNotEmpty) {
        full = await _repository.category(snapshotKey);
      }
      full ??= categories.cast<RealEstateCategoryModel?>().firstWhere(
            (RealEstateCategoryModel? c) => c?.id == property.categoryId,
            orElse: () => null,
          );

      List<RealEstateGeoOption> localities = const <RealEstateGeoOption>[];
      if (property.cityId != null && property.cityId!.isNotEmpty) {
        localities = await _repository.localities(property.cityId!);
      }

      final List<String> media = <String>[];
      for (final Map<String, dynamic> item in property.media) {
        final String? url = item['url']?.toString();
        if (url != null && url.isNotEmpty) media.add(url);
      }

      emit(state.copyWith(
        status: ListingFormStatus.ready,
        propertyId: () => property.id,
        categories: categories,
        selectedCategory: () => full,
        cities: cities,
        localities: localities,
        selectedCityId: () => property.cityId,
        selectedLocalityId: () => property.localityId,
        specs: Map<String, dynamic>.from(property.specs ?? const <String, dynamic>{}),
        amenities: Set<String>.from(property.amenities),
        mediaUrls: media,
        lat: () => property.latitude,
        lng: () => property.longitude,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ListingFormStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ListingFormStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onListingFormCategorySelected(
    ListingFormCategorySelected event,
    Emitter<ListingFormState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategory: () => null,
      specs: const <String, dynamic>{},
      amenities: const <String>{},
      message: '',
    ));
    try {
      final RealEstateCategoryModel? full = await _repository.category(event.key);
      if (full != null) {
        emit(state.copyWith(selectedCategory: () => full));
      } else {
        emit(state.copyWith(message: 'Could not load that category — try again'));
      }
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(message: e.message));
    } catch (e) {
      emit(state.copyWith(message: e.toString()));
    }
  }

  Future<void> _onListingFormCitySelected(
    ListingFormCitySelected event,
    Emitter<ListingFormState> emit,
  ) async {
    emit(state.copyWith(
      selectedCityId: () => event.id,
      selectedLocalityId: () => null,
      localities: const <RealEstateGeoOption>[],
    ));
    if (event.id == null || event.id!.isEmpty) return;
    try {
      final List<RealEstateGeoOption> localities = await _repository.localities(event.id!);
      emit(state.copyWith(localities: localities));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(message: e.message));
    } catch (e) {
      emit(state.copyWith(message: e.toString()));
    }
  }

  void _onListingFormLocalitySelected(
    ListingFormLocalitySelected event,
    Emitter<ListingFormState> emit,
  ) {
    emit(state.copyWith(selectedLocalityId: () => event.id));
  }

  void _onListingFormCoordsChanged(
    ListingFormCoordsChanged event,
    Emitter<ListingFormState> emit,
  ) {
    emit(state.copyWith(lat: () => event.lat, lng: () => event.lng));
  }

  void _onListingFormSpecChanged(
    ListingFormSpecChanged event,
    Emitter<ListingFormState> emit,
  ) {
    final Map<String, dynamic> specs = Map<String, dynamic>.from(state.specs);
    if (event.value == null) {
      specs.remove(event.key);
    } else {
      specs[event.key] = event.value;
    }
    emit(state.copyWith(specs: specs));
  }

  void _onListingFormAmenityToggled(
    ListingFormAmenityToggled event,
    Emitter<ListingFormState> emit,
  ) {
    final Set<String> amenities = Set<String>.from(state.amenities);
    if (!amenities.remove(event.value)) amenities.add(event.value);
    emit(state.copyWith(amenities: amenities));
  }

  Future<void> _onListingFormMediaPicked(
    ListingFormMediaPicked event,
    Emitter<ListingFormState> emit,
  ) async {
    if (state.mediaUrls.length >= 20) {
      emit(state.copyWith(message: 'At most 20 photos per listing'));
      return;
    }
    emit(state.copyWith(uploading: state.uploading + 1));
    try {
      final String path = await _repository.uploadMediaImage(event.file);
      emit(state.copyWith(
        mediaUrls: <String>[...state.mediaUrls, path],
        uploading: state.uploading - 1,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(uploading: state.uploading - 1, message: e.message));
    } catch (e) {
      emit(state.copyWith(uploading: state.uploading - 1, message: e.toString()));
    }
  }

  void _onListingFormMediaRemoved(
    ListingFormMediaRemoved event,
    Emitter<ListingFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.mediaUrls.length) return;
    final List<String> media = List<String>.from(state.mediaUrls)..removeAt(event.index);
    emit(state.copyWith(mediaUrls: media));
  }

  Future<void> _onListingFormSubmitted(
    ListingFormSubmitted event,
    Emitter<ListingFormState> emit,
  ) async {
    if (state.uploading > 0) {
      emit(state.copyWith(message: 'Photos are still uploading — wait a moment'));
      return;
    }
    final ListingFormBasics basics = event.basics;
    final List<SpecFieldDescriptor> fields = specFieldsOf(state.selectedCategory?.specSchema);
    final String? problem = validateListingInput(
      title: basics.title,
      transactionType: basics.transactionType,
      allowedTransactions: state.selectedCategory?.transactionTypes,
      price: basics.price,
      categoryId: state.selectedCategory?.id,
      cityId: state.selectedCityId,
      localityId: state.selectedLocalityId,
      lat: state.lat,
      lng: state.lng,
      specFields: fields,
      specs: state.specs,
      amenities: state.amenities.toList(),
      mediaUrls: state.mediaUrls,
      pincode: basics.pincode,
    );
    if (problem != null) {
      emit(state.copyWith(message: problem));
      return;
    }

    // Send only descriptor-known spec keys when descriptors loaded;
    // otherwise pass the untouched originals through (edit without a
    // resolvable category must not drop saved data).
    Map<String, dynamic> specs = Map<String, dynamic>.from(state.specs);
    if (fields.isNotEmpty) {
      final Set<String> known = fields.map((SpecFieldDescriptor f) => f.key).toSet();
      specs.removeWhere((String key, dynamic value) => !known.contains(key) || value == null);
    } else {
      specs.removeWhere((String key, dynamic value) => value == null);
    }

    emit(state.copyWith(status: ListingFormStatus.submitting, message: ''));
    try {
      final Map<String, dynamic> payload = buildListingPayload(
        title: basics.title.trim(),
        description: basics.description?.trim(),
        transactionType: basics.transactionType,
        price: basics.price!,
        priceOnRequest: basics.priceOnRequest,
        categoryId: state.selectedCategory!.id,
        addressLine: basics.addressLine?.trim(),
        localityId: state.selectedLocalityId!,
        cityId: state.selectedCityId!,
        lng: state.lng!,
        lat: state.lat!,
        pincode: basics.pincode?.trim(),
        mapAddress: basics.mapAddress?.trim(),
        specs: specs,
        amenities: state.amenities.toList(),
        mediaUrls: state.mediaUrls,
        projectName: basics.projectName?.trim(),
        builderName: basics.builderName?.trim(),
      );
      if (state.isEdit) {
        await _repository.updateProperty(state.propertyId!, payload);
      } else {
        await _repository.createProperty(payload);
      }
      emit(state.copyWith(status: ListingFormStatus.success));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ListingFormStatus.ready, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ListingFormStatus.ready, message: e.toString()));
    }
  }
}
