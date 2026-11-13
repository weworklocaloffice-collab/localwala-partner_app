/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'listing_detail_bloc.dart';

abstract class ListingDetailEvent {
  const ListingDetailEvent();
}

/// Loads the property and its documents together.
class ListingDetailLoadRequested extends ListingDetailEvent {
  final String id;

  const ListingDetailLoadRequested(this.id);
}

/// Moves the listing to [target] after the confirm dialog. Only
/// vendor-reachable targets are offered (see [availableDetailActions]);
/// anything else fails closed in the handler, not just the UI.
class ListingDetailTransitionRequested extends ListingDetailEvent {
  final String target;
  final String? reason;

  const ListingDetailTransitionRequested(this.target, {this.reason});
}

/// Reloads everything (pull-to-refresh, and after the edit form saves).
class ListingDetailRefreshed extends ListingDetailEvent {
  const ListingDetailRefreshed();
}

/// Marks content changed without a reload (edit form saved elsewhere).
/// The screen pops with `true` so the listings tab refreshes.
class ListingDetailContentChanged extends ListingDetailEvent {
  const ListingDetailContentChanged();
}
