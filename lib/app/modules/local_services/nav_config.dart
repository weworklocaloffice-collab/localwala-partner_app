/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/local_services/partner/partner_shell_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// Roles this module can hold. Mirrors `API/src/config/roles.js`.
/// Wire value is the SERVER value (`localServicesPartner`) — never shortened.
enum LocalServicesAppRole {
  /// Service provider. Owns offerings, jobs and availability.
  partner('localServicesPartner', 'Partner');

  const LocalServicesAppRole(this.wire, this.label);

  final String wire;
  final String label;

  static LocalServicesAppRole? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final LocalServicesAppRole role in LocalServicesAppRole.values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// The Local Services module's shell registry. Separate module, separate
/// registry — a change here must never break dairy/jhatka/realestate.
class LocalServicesShell {
  final String role;
  final String label;
  final Widget Function(RoleGateState state) build;

  const LocalServicesShell({
    required this.role,
    required this.label,
    required this.build,
  });
}

final List<LocalServicesShell> localServicesShells = <LocalServicesShell>[
  LocalServicesShell(
    role: LocalServicesAppRole.partner.wire,
    label: LocalServicesAppRole.partner.label,
    build: (state) => LocalServicesPartnerShellScreen(gate: state),
  ),
];

LocalServicesShell? findLocalServicesShell(String role) {
  for (final shell in localServicesShells) {
    if (shell.role == role) return shell;
  }
  return null;
}

LocalServicesShell get defaultLocalServicesShell => localServicesShells.first;
