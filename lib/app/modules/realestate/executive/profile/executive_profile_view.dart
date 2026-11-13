/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partner/app/modules/realestate/executive/profile/bloc/executive_profile_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Executive identity: name, availability and assignment scope from
/// `GET /executive/me`, plus a manual position update.
///
/// The stored position is informational — check-in always measures the
/// coordinates sent with it (BR-08), not this point.
class ExecutiveProfileScreen extends StatelessWidget {
  const ExecutiveProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveProfileBloc>(
      create: (_) => ExecutiveProfileBloc()..add(const ExecutiveProfileLoad()),
      child: BlocBuilder<ExecutiveProfileBloc, ExecutiveProfileState>(
        builder: (BuildContext context, ExecutiveProfileState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavProfile)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case ExecutiveProfileStatus.initial:
                  case ExecutiveProfileStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ExecutiveProfileStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<ExecutiveProfileBloc>().add(const ExecutiveProfileLoad()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case ExecutiveProfileStatus.loaded:
                    final Map<String, dynamic> me = state.me;
                    final dynamic available = me['available'] ?? me['isAvailable'];
                    final List<MapEntry<String, String>> rows = <MapEntry<String, String>>[
                      MapEntry(l10n.realEstateExecName, '${me['name'] ?? me['displayName'] ?? '—'}'),
                      MapEntry(l10n.realEstateExecMobile, '${me['mobile'] ?? '—'}'),
                      MapEntry(
                        l10n.realEstateExecAvailable,
                        available == null
                            ? '—'
                            : available == true
                                ? l10n.realEstateExecYes
                                : l10n.realEstateExecNo,
                      ),
                      MapEntry(l10n.realEstateCheckoutStatus, '${me['status'] ?? '—'}'),
                    ];
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<ExecutiveProfileBloc>().add(const ExecutiveProfileLoad()),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            ...rows.map(
                              (MapEntry<String, String> e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.key),
                                trailing: Text(e.value),
                              ),
                            ),
                            if (state.locationSaved)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(l10n.realEstateExecLocationUpdated),
                              ),
                            if (state.locationMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(state.locationMessage),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: state.updatingLocation
                                  ? null
                                  : () async {
                                      try {
                                        LocationPermission perm = await Geolocator.checkPermission();
                                        if (perm == LocationPermission.denied) {
                                          perm = await Geolocator.requestPermission();
                                        }
                                        if (perm == LocationPermission.denied ||
                                            perm == LocationPermission.deniedForever) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(l10n.realEstateExecLocationPermissionRequired)),
                                          );
                                          return;
                                        }
                                        final Position pos = await Geolocator.getCurrentPosition();
                                        if (!context.mounted) return;
                                        context.read<ExecutiveProfileBloc>().add(
                                              ExecutiveProfileLocationUpdate(lng: pos.longitude, lat: pos.latitude),
                                            );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${l10n.realEstateExecLocationUpdateFailed}: $e'),
                                          ),
                                        );
                                      }
                                    },
                              icon: state.updatingLocation
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location_outlined),
                              label: Text(l10n.realEstateExecUpdateLocation),
                            ),
                          ],
                        ),
                      ),
                    );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
