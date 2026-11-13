/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vertical_picker_bloc.dart';

enum VerticalPickerStatus { initial, loading, resolved }

class VerticalPickerState {
  final VerticalPickerStatus status;

  /// Verticals this build can render and the session may enter.
  final List<VerticalMeta> options;

  /// Set once the user taps an option; the view forwards it to
  /// `onPicked` exactly once.
  final String? selectedVertical;

  const VerticalPickerState({
    this.status = VerticalPickerStatus.initial,
    this.options = const <VerticalMeta>[],
    this.selectedVertical,
  });

  bool get hasSelection => selectedVertical != null && selectedVertical!.isNotEmpty;

  VerticalPickerState copyWith({
    VerticalPickerStatus? status,
    List<VerticalMeta>? options,
    String? selectedVertical,
  }) {
    return VerticalPickerState(
      status: status ?? this.status,
      options: options ?? this.options,
      selectedVertical: selectedVertical ?? this.selectedVertical,
    );
  }
}
