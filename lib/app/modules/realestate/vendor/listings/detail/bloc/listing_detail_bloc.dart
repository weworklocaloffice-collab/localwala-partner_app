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

part 'listing_detail_event.dart';
part 'listing_detail_state.dart';

/// A transition the vendor may attempt from the current status.
///
/// Derived from the server tables (`STATUS_TRANSITIONS` reachable +
/// `STATUS_ACTORS` listing `vendor`): a vendor moves DRAFT/CHANGES_REQUIRED
/// to SUBMITTED and anything non-terminal to ARCHIVED — nothing else.
/// The server re-enforces both tables; this mapping only decides which
/// buttons render.
enum DetailActionKind { submit, resubmit, withdraw, archive }

class DetailAction {
  final String target;
  final DetailActionKind kind;

  const DetailAction({required this.target, required this.kind});
}

List<DetailAction> availableDetailActions(String? status) {
  switch (status) {
    case 'DRAFT':
      return const <DetailAction>[
        DetailAction(target: 'SUBMITTED', kind: DetailActionKind.submit),
        DetailAction(target: 'ARCHIVED', kind: DetailActionKind.withdraw),
      ];
    case 'CHANGES_REQUIRED':
      return const <DetailAction>[
        DetailAction(target: 'SUBMITTED', kind: DetailActionKind.resubmit),
        DetailAction(target: 'ARCHIVED', kind: DetailActionKind.withdraw),
      ];
    case 'SUBMITTED':
    case 'IN_REVIEW':
    case 'APPROVED':
      return const <DetailAction>[
        DetailAction(target: 'ARCHIVED', kind: DetailActionKind.withdraw),
      ];
    case 'PUBLISHED':
    case 'SOLD':
    case 'RENTED':
    case 'SUSPENDED':
    case 'EXPIRED':
    case 'REJECTED':
      return const <DetailAction>[
        DetailAction(target: 'ARCHIVED', kind: DetailActionKind.archive),
      ];
    case 'ARCHIVED':
    default:
      return const <DetailAction>[];
  }
}

/// One timeline entry: a lifecycle moment with its date, when known.
class ListingMilestone {
  final String label;
  final DateTime? at;

  const ListingMilestone({required this.label, required this.at});
}

/// Status timeline from the dates the wire carries. Moments without a
/// date are omitted — a timeline that invents dates is worse than a
/// short one.
List<ListingMilestone> listingMilestones(RealEstatePropertyModel property) {
  return <ListingMilestone>[
    ListingMilestone(label: 'Created', at: property.createdAt),
    ListingMilestone(label: 'Submitted', at: property.submittedAt),
    ListingMilestone(label: 'Published', at: property.publishedAt),
    ListingMilestone(label: 'Expires', at: property.expiresAt),
  ].where((ListingMilestone m) => m.at != null).toList();
}

/// One listing in full: header facts, status timeline, documents, and
/// the vendor-reachable transitions behind confirm dialogs.
///
/// A transition reloads the property so the new status, counters and
/// timeline render from the server — never optimistically. Failures
/// keep the loaded content with a message (snackbar), never a crash.
class ListingDetailBloc extends Bloc<ListingDetailEvent, ListingDetailState> {
  ListingDetailBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const ListingDetailState()) {
    on<ListingDetailLoadRequested>(_onListingDetailLoadRequested);
    on<ListingDetailTransitionRequested>(_onListingDetailTransitionRequested);
    on<ListingDetailRefreshed>(_onListingDetailRefreshed);
    on<ListingDetailContentChanged>(_onListingDetailContentChanged);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<ListingDetailState> emit, String id) async {
    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _repository.property(id),
        _repository.documents(id),
      ]);
      final RealEstatePropertyModel? property = results[0] as RealEstatePropertyModel?;
      if (property == null) {
        emit(state.copyWith(status: ListingDetailStatus.failure, message: 'Listing not found'));
        return;
      }
      emit(state.copyWith(
        status: ListingDetailStatus.loaded,
        property: () => property,
        documents: (results[1] as List<RealEstateDocumentModel>),
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ListingDetailStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ListingDetailStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onListingDetailLoadRequested(
    ListingDetailLoadRequested event,
    Emitter<ListingDetailState> emit,
  ) async {
    emit(state.copyWith(status: ListingDetailStatus.loading, message: ''));
    await _load(emit, event.id);
  }

  Future<void> _onListingDetailTransitionRequested(
    ListingDetailTransitionRequested event,
    Emitter<ListingDetailState> emit,
  ) async {
    final RealEstatePropertyModel? property = state.property;
    if (property == null || state.transitioning) return;
    final bool offered =
        availableDetailActions(property.status).any((DetailAction a) => a.target == event.target);
    if (!offered) {
      emit(state.copyWith(message: 'That move is not available from ${property.status}'));
      return;
    }
    emit(state.copyWith(transitioning: true, message: ''));
    try {
      if (event.target == 'SUBMITTED') {
        await _repository.submitProperty(property.id);
      } else if (event.target == 'ARCHIVED' && property.status == 'DRAFT') {
        await _repository.withdrawProperty(property.id);
      } else {
        await _repository.changePropertyStatus(property.id, event.target, reason: event.reason);
      }
      final RealEstatePropertyModel? fresh = await _repository.property(property.id);
      emit(state.copyWith(
        transitioning: false,
        changed: true,
        property: () => fresh ?? property,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(transitioning: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(transitioning: false, message: e.toString()));
    }
  }

  Future<void> _onListingDetailRefreshed(
    ListingDetailRefreshed event,
    Emitter<ListingDetailState> emit,
  ) async {
    final RealEstatePropertyModel? property = state.property;
    if (property == null) return;
    emit(state.copyWith(status: ListingDetailStatus.loading, message: ''));
    await _load(emit, property.id);
  }

  void _onListingDetailContentChanged(
    ListingDetailContentChanged event,
    Emitter<ListingDetailState> emit,
  ) {
    emit(state.copyWith(changed: true));
  }
}
