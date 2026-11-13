import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Required physical outlet location setup, kept separate from the owner login
/// profile and from the delivery localities the outlet serves.
class PartnerOutletLocationScreen extends StatefulWidget {
  const PartnerOutletLocationScreen({super.key, this.repository, this.onSaved});

  final PartnerRepository? repository;
  final VoidCallback? onSaved;

  @override
  State<PartnerOutletLocationScreen> createState() => _PartnerOutletLocationScreenState();
}

class _PartnerOutletLocationScreenState extends State<PartnerOutletLocationScreen> {
  late final PartnerRepository _repository = widget.repository ?? PartnerRepository();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _primaryLocality = '';
  String _city = '';
  LatLng? _pin;
  LatLng? _referenceLocalityCenter;
  GoogleMapController? _mapController;

  bool get _hasMapsKey => Environments.googleMapsKey.trim().isNotEmpty;
  bool get _showMap => _hasMapsKey && !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  String _name(dynamic value) {
    final Map<String, dynamic> row = _map(value);
    return (row['name'] ?? '').toString();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final DioApiResponse response = await _repository.partnerBusinessProfile();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load outlet location details. Please retry.';
      });
      return;
    }
    final Map<String, dynamic> profile = _map(decodeBody(response)['profile']);
    final List<dynamic> coordinates = profile['coordinates'] as List? ?? const <dynamic>[];
    final Map<String, dynamic> locality = _map(profile['locality']);
    final Map<String, dynamic> localityLocation = _map(locality['location']);
    final List<dynamic> localityCoordinates = localityLocation['coordinates'] as List? ?? const <dynamic>[];
    LatLng? pin;
    if (coordinates.length == 2) {
      final double? longitude = double.tryParse(coordinates[0].toString());
      final double? latitude = double.tryParse(coordinates[1].toString());
      if (latitude != null && longitude != null) pin = LatLng(latitude, longitude);
    }
    LatLng? referenceCenter;
    if (localityCoordinates.length == 2) {
      final double? longitude = double.tryParse(localityCoordinates[0].toString());
      final double? latitude = double.tryParse(localityCoordinates[1].toString());
      if (latitude != null && longitude != null) referenceCenter = LatLng(latitude, longitude);
    }
    setState(() {
      _loading = false;
      _address.text = profile['address']?.toString() ?? '';
      _primaryLocality = _name(profile['locality']);
      _city = _name(profile['city']);
      _referenceLocalityCenter = referenceCenter;
      _setPinFields(pin);
    });
  }

  void _moveMap(LatLng point) {
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: point, zoom: 16),
    ));
  }

  void _focusRegisteredLocality() {
    final LatLng? center = _referenceLocalityCenter;
    if (center == null) {
      _message('The registered locality map point is unavailable. Contact platform support to correct the locality record.');
      return;
    }
    _moveMap(center);
  }

  void _setPinFields(LatLng? value) {
    _pin = value;
    _latitude.text = value == null ? '' : value.latitude.toStringAsFixed(6);
    _longitude.text = value == null ? '' : value.longitude.toStringAsFixed(6);
  }

  void _readManualCoordinates() {
    final double? latitude = double.tryParse(_latitude.text.trim());
    final double? longitude = double.tryParse(_longitude.text.trim());
    if (latitude == null || longitude == null || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      setState(() => _pin = null);
      return;
    }
    setState(() => _pin = LatLng(latitude, longitude));
  }

  Future<void> _useCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _message('Turn on device location, then try again.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _message('Allow location access to place the outlet pin.');
      return;
    }
    try {
      final Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final LatLng point = LatLng(position.latitude, position.longitude);
      setState(() => _setPinFields(point));
      _moveMap(point);
    } catch (_) {
      _message('Could not read the device location. You can enter the coordinates manually.');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final String address = _address.text.trim();
    if (address.length < 8) {
      _message('Enter the complete outlet address, including street and a nearby landmark.');
      return;
    }
    _readManualCoordinates();
    if (_pin == null) {
      _message('Set the outlet map pin before saving.');
      return;
    }
    setState(() => _saving = true);
    final DioApiResponse response = await _repository.updatePartnerOutletLocation(
      address: address,
      longitude: _pin!.longitude,
      latitude: _pin!.latitude,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.errorType != NetErrorType.none) {
      final dynamic data = response.response?.data;
      final String message = data is Map
          ? (data['message']?.toString() ?? 'Outlet location could not be saved.')
          : 'Outlet location could not be saved.';
      _message(message);
      return;
    }
    final Map<String, dynamic> saved = _map(decodeBody(response)['profile']);
    if (saved['locationComplete'] != true) {
      _message('The server could not confirm the outlet address and pin. Please review and save again.');
      return;
    }
    widget.onSaved?.call();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Outlet address and pin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ]),
                ))
              : SafeArea(child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: <Widget>[
                    Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          const Text('Required before you can operate', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('Set the physical outlet address and place a pin at the outlet entrance. Your registered primary locality stays fixed and is used as the map reference.'),
                          if (_primaryLocality.isNotEmpty || _city.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text('Primary locality: ${<String>[_primaryLocality, _city].where((String part) => part.isNotEmpty).join(', ')}'),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Complete outlet address',
                        hintText: 'Door or shop number, street, landmark and PIN code',
                        helperText: 'This is the physical outlet address, not your delivery area.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store_mall_directory_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: <Widget>[
                      Expanded(child: Text('Outlet map pin', style: Theme.of(context).textTheme.titleMedium)),
                      if (_showMap && _referenceLocalityCenter != null)
                        IconButton(
                          tooltip: 'Focus registered locality',
                          onPressed: _saving ? null : _focusRegisteredLocality,
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _useCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use GPS'),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (_showMap && (_referenceLocalityCenter != null || _pin != null))
                      SizedBox(
                        height: 280,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _referenceLocalityCenter ?? _pin!,
                              zoom: 15.5,
                            ),
                            onMapCreated: (GoogleMapController controller) => _mapController = controller,
                            onTap: (LatLng point) => setState(() => _setPinFields(point)),
                            markers: _pin == null
                                ? const <Marker>{}
                                : <Marker>{Marker(
                                    markerId: const MarkerId('dairy-outlet'),
                                    position: _pin!,
                                    draggable: true,
                                    onDragEnd: (LatLng point) => setState(() => _setPinFields(point)),
                                  )},
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                          ),
                        ),
                      )
                    else if (_showMap)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(_primaryLocality.isEmpty
                              ? 'Your registered locality is missing, so the map cannot be centered. Contact platform support to correct your registration.'
                              : 'The map reference point for $_primaryLocality is missing. You can use GPS or enter coordinates, but contact platform support to correct the locality map point.'),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(_hasMapsKey
                              ? 'Use GPS or enter the exact pin coordinates below.'
                              : 'Map preview needs the Google Maps key. Use GPS or enter the pin coordinates below.'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _showMap
                          ? 'Move the map and tap to place the pin, or drag the marker. The locality center is a reference point; its exact boundary is not currently stored in the locality data.'
                          : 'Use GPS or enter coordinates. The server checks the pin against registered locality reference points; those points are not surveyed boundaries.',
                    ),
                    const SizedBox(height: 12),
                    Row(children: <Widget>[
                      Expanded(child: TextField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                        onChanged: (_) => _readManualCoordinates(),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                        onChanged: (_) => _readManualCoordinates(),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving outlet location' : 'Save and unlock operations'),
                    ),
                  ],
                )),
    );
  }
}
