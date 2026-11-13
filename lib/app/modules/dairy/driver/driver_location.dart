import 'package:geolocator/geolocator.dart';

/// Returns a GeoJSON point for run and stop audit events when location access
/// is available. The caller can continue with a null point if permission or GPS
/// is unavailable; field operations should not be stranded by a device setting.
Future<Map<String, dynamic>?> captureDairyDriverPoint() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return <String, dynamic>{
      'type': 'Point',
      'coordinates': <double>[position.longitude, position.latitude],
    };
  } catch (_) {
    return null;
  }
}
