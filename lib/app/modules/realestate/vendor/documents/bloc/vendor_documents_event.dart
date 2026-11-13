/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_documents_bloc.dart';

abstract class VendorDocumentsEvent {
  const VendorDocumentsEvent();
}

/// Loads the vendor's properties for the picker.
class VendorDocumentsPropertiesRequested extends VendorDocumentsEvent {
  const VendorDocumentsPropertiesRequested();
}

/// Selects a property and loads its documents.
class VendorDocumentsPropertySelected extends VendorDocumentsEvent {
  const VendorDocumentsPropertySelected(this.propertyId);

  final String propertyId;
}

/// Deletes a PENDING document (ACCEPTED answers 409 — BR-21).
class VendorDocumentDeleteRequested extends VendorDocumentsEvent {
  const VendorDocumentDeleteRequested(this.propertyId, this.documentId);

  final String propertyId;
  final String documentId;
}
