import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner/app/modules/realestate/executive/navigation/bloc/executive_navigation_bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ExecutiveNavigationScreen extends StatelessWidget {
  const ExecutiveNavigationScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveNavigationBloc>(
      create: (_) => ExecutiveNavigationBloc()..add(ExecutiveNavigationLoad(propertyId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: BlocBuilder<ExecutiveNavigationBloc, ExecutiveNavigationState>(
          builder: (BuildContext context, ExecutiveNavigationState state) {
            switch (state.status) {
              case ExecutiveNavigationStatus.initial:
              case ExecutiveNavigationStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveNavigationStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveNavigationBloc>().add(ExecutiveNavigationRefreshed(propertyId)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveNavigationStatus.loaded:
                final RealEstatePropertyModel? p = state.property;
                final double? lat = p?.latitude;
                final double? lng = p?.longitude;
                if (lat == null || lng == null) {
                  return Center(child: Text('No location available'));
                }
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
                        markers: <Marker>{Marker(markerId: const MarkerId('property'), position: LatLng(lat, lng))},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Open in Maps'),
                        onPressed: () async {
                          final Uri uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}
