/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'listing_form_bloc.dart';

abstract class ListingFormEvent {
  const ListingFormEvent();
}

/// User picked a category: the full doc (specSchema, amenities,
/// transaction types) is fetched and specs/amenities reset.
class ListingFormCategorySelected extends ListingFormEvent {
  final String key;

  const ListingFormCategorySelected(this.key);
}

/// User picked a city: localities reload and the locality clears.
class ListingFormCitySelected extends ListingFormEvent {
  final String? id;

  const ListingFormCitySelected(this.id);
}

class ListingFormLocalitySelected extends ListingFormEvent {
  final String? id;

  const ListingFormLocalitySelected(this.id);
}

class ListingFormCoordsChanged extends ListingFormEvent {
  final double lat;
  final double lng;

  const ListingFormCoordsChanged({required this.lat, required this.lng});
}

class ListingFormSpecChanged extends ListingFormEvent {
  final String key;
  final dynamic value;

  const ListingFormSpecChanged({required this.key, required this.value});
}

class ListingFormAmenityToggled extends ListingFormEvent {
  final String value;

  const ListingFormAmenityToggled(this.value);
}

class ListingFormMediaRemoved extends ListingFormEvent {
  final int index;

  const ListingFormMediaRemoved(this.index);
}

/// Validates and creates (or updates, when the form was loaded with a
/// property) the listing.
class ListingFormSubmitted extends ListingFormEvent {
  final ListingFormBasics basics;

  const ListingFormSubmitted(this.basics);
}
