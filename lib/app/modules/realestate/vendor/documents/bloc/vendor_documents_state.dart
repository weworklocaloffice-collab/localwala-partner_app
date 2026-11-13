/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_documents_bloc.dart';

enum VendorDocumentsStatus { initial, loading, loaded, failure }

class VendorDocumentsState {
  final VendorDocumentsStatus status;
  final List<RealEstatePropertyModel> properties;
  final String? selectedPropertyId;
  final List<RealEstateDocumentModel> documents;
  final String message;

  const VendorDocumentsState({
    this.status = VendorDocumentsStatus.initial,
    this.properties = const <RealEstatePropertyModel>[],
    this.selectedPropertyId,
    this.documents = const <RealEstateDocumentModel>[],
    this.message = '',
  });

  VendorDocumentsState copyWith({
    VendorDocumentsStatus? status,
    List<RealEstatePropertyModel>? properties,
    String? selectedPropertyId,
    List<RealEstateDocumentModel>? documents,
    String? message,
  }) {
    return VendorDocumentsState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      documents: documents ?? this.documents,
      message: message ?? this.message,
    );
  }
}
