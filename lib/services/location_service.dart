import 'package:geolocator/geolocator.dart';

class LocationService {

  static Position? _cachedPosition;
  static DateTime? _lastFetch;

  static Future<Position> getCurrentLocation() async {

    if (_cachedPosition != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inSeconds < 30) {
      return _cachedPosition!;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();

    _cachedPosition = position;
    _lastFetch = DateTime.now();

    return position;
  }
}