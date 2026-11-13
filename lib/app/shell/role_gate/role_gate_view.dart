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

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shell switcher for the active vertical.
///
/// Dairy sessions choose between the partner and driver shells;
/// realestate sessions choose between the vendor and executive shells
/// the session holds. The shells never blend — picking one re-emits
/// the gate and the app shell dispatches into that module.
class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return BlocBuilder<RoleGateBloc, RoleGateState>(
      builder: (BuildContext context, RoleGateState state) {
        final bool isRealEstate = (state.session?.activeVertical ?? '') == 'realestate';
        final bool isJhatka = (state.session?.activeVertical ?? '') == 'jhatka';
        final bool canSwitchBusiness = state.availableVerticals.length > 1;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.activeRole,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (isRealEstate) ...<Widget>[
                      _ShellChoice(
                        label: l10n.realEstateVendorShell,
                        icon: Icons.apartment_outlined,
                        selected: state.activeRealEstateShell == 'vendor',
                        enabled: state.availableRealEstateShells.contains('vendor'),
                        color: theme.primary,
                        onTap: state.availableRealEstateShells.contains('vendor')
                            ? () => context.read<RoleGateBloc>().add(const RoleGateSwitchRealEstateShellEvent('vendor'))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _ShellChoice(
                        label: l10n.realEstateExecutiveShell,
                        icon: Icons.badge_outlined,
                        selected: state.activeRealEstateShell == 'executive',
                        enabled: state.availableRealEstateShells.contains('executive'),
                        color: theme.secondary,
                        onTap: state.availableRealEstateShells.contains('executive')
                            ? () => context
                                .read<RoleGateBloc>()
                                .add(const RoleGateSwitchRealEstateShellEvent('executive'))
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (state.availableRealEstateShells.length <= 1)
                        Text(
                          l10n.noOtherRoleAvailable,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ] else if (isJhatka) ...<Widget>[
                      _ShellChoice(
                        label: 'Jhatka partner',
                        icon: Icons.storefront_outlined,
                        selected: state.activeRole == DairyAppRole.jhatkaPartner,
                        enabled: state.availableRoles.contains(DairyAppRole.jhatkaPartner),
                        color: theme.primary,
                        onTap: state.availableRoles.contains(DairyAppRole.jhatkaPartner)
                            ? () => context
                                .read<RoleGateBloc>()
                                .add(const RoleGateSwitchEvent(DairyAppRole.jhatkaPartner))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _ShellChoice(
                        label: 'Jhatka rider',
                        icon: Icons.pedal_bike_outlined,
                        selected: state.activeRole == DairyAppRole.jhatkaDriver,
                        enabled: state.availableRoles.contains(DairyAppRole.jhatkaDriver),
                        color: theme.secondary,
                        onTap: state.availableRoles.contains(DairyAppRole.jhatkaDriver)
                            ? () => context
                                .read<RoleGateBloc>()
                                .add(const RoleGateSwitchEvent(DairyAppRole.jhatkaDriver))
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (state.availableRoles.length <= 1)
                        Text(
                          l10n.noOtherRoleAvailable,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ] else ...<Widget>[
                      _ShellChoice(
                        label: l10n.partnerShell,
                        icon: Icons.storefront_outlined,
                        selected: state.activeRole == DairyAppRole.partner,
                        enabled: state.availableRoles.contains(DairyAppRole.partner),
                        color: theme.primary,
                        onTap: state.availableRoles.contains(DairyAppRole.partner)
                            ? () => context.read<RoleGateBloc>().add(const RoleGateSwitchEvent(DairyAppRole.partner))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _ShellChoice(
                        label: l10n.deliveryShell,
                        icon: Icons.pedal_bike_outlined,
                        selected: state.activeRole == DairyAppRole.driver,
                        enabled: state.availableRoles.contains(DairyAppRole.driver),
                        color: theme.secondary,
                        onTap: state.availableRoles.contains(DairyAppRole.driver)
                            ? () => context.read<RoleGateBloc>().add(const RoleGateSwitchEvent(DairyAppRole.driver))
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (state.availableRoles.length <= 1)
                        Text(
                          l10n.noOtherRoleAvailable,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                    if (canSwitchBusiness) ...<Widget>[
                      const SizedBox(height: 8),
                      TextButton(
                        // Unmake the vertical choice: the picker runs again
                        // on the next gate build.
                        onPressed: () => context.read<RoleGateBloc>().add(const RoleGatePickVerticalEvent('')),
                        child: Text(l10n.realEstateSwitchBusiness),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShellChoice extends StatelessWidget {
  const _ShellChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? color : theme.divider, width: selected ? 1.6 : 1),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: selected ? color : theme.bodyText),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? color : theme.titleText,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
