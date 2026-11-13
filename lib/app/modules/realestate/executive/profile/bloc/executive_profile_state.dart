/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_profile_bloc.dart';

enum ExecutiveProfileStatus { initial, loading, loaded, failure }

class ExecutiveProfileState {
  final ExecutiveProfileStatus status;
  final Map<String, dynamic> me;
  final String message;
  final bool updatingLocation;
  final bool locationSaved;
  final String locationMessage;

  const ExecutiveProfileState({
    this.status = ExecutiveProfileStatus.initial,
    this.me = const <String, dynamic>{},
    this.message = '',
    this.updatingLocation = false,
    this.locationSaved = false,
    this.locationMessage = '',
  });

  ExecutiveProfileState copyWith({
    ExecutiveProfileStatus? status,
    Map<String, dynamic>? me,
    String? message,
    bool? updatingLocation,
    bool? locationSaved,
    String? locationMessage,
  }) {
    return ExecutiveProfileState(
      status: status ?? this.status,
      me: me ?? this.me,
      message: message ?? this.message,
      updatingLocation: updatingLocation ?? this.updatingLocation,
      locationSaved: locationSaved ?? this.locationSaved,
      locationMessage: locationMessage ?? this.locationMessage,
    );
  }
}
