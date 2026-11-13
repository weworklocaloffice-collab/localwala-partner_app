/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_document.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_documents_event.dart';
part 'vendor_documents_state.dart';

/// Property documents (plan §11.3, BR-18, BR-21).
///
/// Upload happens in the listing form (bytes + metadata together); this
/// screen is the verification-status trail per property. Only PENDING
/// documents can be removed — ACCEPTED rows are immutable.
class VendorDocumentsBloc extends Bloc<VendorDocumentsEvent, VendorDocumentsState> {
  VendorDocumentsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorDocumentsState()) {
    on<VendorDocumentsPropertiesRequested>(_onPropertiesRequested);
    on<VendorDocumentsPropertySelected>(_onPropertySelected);
    on<VendorDocumentDeleteRequested>(_onDeleteRequested);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _onPropertiesRequested(
    VendorDocumentsPropertiesRequested event,
    Emitter<VendorDocumentsState> emit,
  ) async {
    emit(state.copyWith(status: VendorDocumentsStatus.loading, message: ''));
    try {
      final RealEstatePage<RealEstatePropertyModel> page =
          await _repository.properties(limit: 50);
      emit(state.copyWith(
        status: VendorDocumentsStatus.loaded,
        properties: page.items,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onPropertySelected(
    VendorDocumentsPropertySelected event,
    Emitter<VendorDocumentsState> emit,
  ) async {
    emit(state.copyWith(
      status: VendorDocumentsStatus.loading,
      selectedPropertyId: event.propertyId,
      message: '',
    ));
    try {
      final List<RealEstateDocumentModel> docs =
          await _repository.documents(event.propertyId);
      emit(state.copyWith(status: VendorDocumentsStatus.loaded, documents: docs));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    VendorDocumentDeleteRequested event,
    Emitter<VendorDocumentsState> emit,
  ) async {
    try {
      await _repository.deleteDocument(event.propertyId, event.documentId);
      final List<RealEstateDocumentModel> docs =
          await _repository.documents(event.propertyId);
      emit(state.copyWith(status: VendorDocumentsStatus.loaded, documents: docs));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorDocumentsStatus.failure, message: e.toString()));
    }
  }
}
