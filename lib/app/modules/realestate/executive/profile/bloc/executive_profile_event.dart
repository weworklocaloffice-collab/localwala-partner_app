/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_profile_bloc.dart';

abstract class ExecutiveProfileEvent {
  const ExecutiveProfileEvent();
}

/// Loads `GET /executive/me`.
class ExecutiveProfileLoad extends ExecutiveProfileEvent {
  const ExecutiveProfileLoad();
}

/// Records the executive's position with device coordinates.
class ExecutiveProfileLocationUpdate extends ExecutiveProfileEvent {
  final double lng;
  final double lat;

  const ExecutiveProfileLocationUpdate({required this.lng, required this.lat});
}
