/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/shell/vertical_picker/bloc/vertical_picker_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen chooser shown when the account spans more than one vertical.
///
/// One card per vertical, tap to enter — the same pattern as the customer
/// app's vertical picker (plan §14.1): the chosen vertical gets a full
/// screen with its own navigation; there is no back, because before a
/// vertical is chosen there is nothing to go back to.
///
/// The pick is reported through [onPicked]; persistence and the re-dispatch
/// into the chosen module belong to the caller (the app shell raises
/// `RoleGatePickVerticalEvent`).
class VerticalPickerView extends StatelessWidget {
  const VerticalPickerView({super.key, required this.session, required this.onPicked});

  /// Resolved session whose `availableVerticals` drive the option list.
  final UserSessionModel session;

  /// Called exactly once, with the id of the tapped vertical.
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VerticalPickerBloc>(
      create: (_) => VerticalPickerBloc()..add(VerticalPickerLoadEvent(session)),
      child: BlocConsumer<VerticalPickerBloc, VerticalPickerState>(
        listenWhen: (VerticalPickerState previous, VerticalPickerState current) =>
            !previous.hasSelection && current.hasSelection,
        listener: (BuildContext context, VerticalPickerState state) => onPicked(state.selectedVertical!),
        builder: (BuildContext context, VerticalPickerState state) {
          final AppThemeData theme =
              appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

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
                        l10n.verticalPickerTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.verticalPickerSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      for (final VerticalMeta option in state.options) ...<Widget>[
                        _VerticalCard(
                          option: option,
                          enabled: state.status == VerticalPickerStatus.resolved && !state.hasSelection,
                          color: theme.primary,
                          onTap: () => context.read<VerticalPickerBloc>().add(VerticalPickerSelectEvent(option.id)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  const _VerticalCard({
    required this.option,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final VerticalMeta option;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Row(
              children: <Widget>[
                Icon(option.icon, color: theme.bodyText),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.titleText),
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.bodyText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
