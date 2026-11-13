/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'listing_detail_bloc.dart';

enum ListingDetailStatus { initial, loading, loaded, failure }

class ListingDetailState {
  final ListingDetailStatus status;
  final RealEstatePropertyModel? property;
  final List<RealEstateDocumentModel> documents;
  final bool transitioning;
  final bool changed;
  final String message;

  const ListingDetailState({
    this.status = ListingDetailStatus.initial,
    this.property,
    this.documents = const <RealEstateDocumentModel>[],
    this.transitioning = false,
    this.changed = false,
    this.message = '',
  });

  ListingDetailState copyWith({
    ListingDetailStatus? status,
    RealEstatePropertyModel? Function()? property,
    List<RealEstateDocumentModel>? documents,
    bool? transitioning,
    bool? changed,
    String? message,
  }) {
    return ListingDetailState(
      status: status ?? this.status,
      property: property != null ? property() : this.property,
      documents: documents ?? this.documents,
      transitioning: transitioning ?? this.transitioning,
      changed: changed ?? this.changed,
      message: message ?? this.message,
    );
  }
}
