import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// =====================
/// ACTUAL LOGIC (MERGED)
/// =====================
class LocationUtils {
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  static String? findNearestSection(
    double userLat,
    double userLng,
    List<Map<String, dynamic>> sections,
  ) {
    double minDistance = double.infinity;
    String? nearestSectionId;

    for (var section in sections) {
      final lat = section['latitude'];
      final lng = section['longitude'];

      if (lat == null || lng == null) continue;

      double distance =
          calculateDistance(userLat, userLng, lat, lng);

      if (distance < minDistance) {
        minDistance = distance;
        nearestSectionId = section['section_id'];
      }
    }

    return nearestSectionId;
  }
}

/// =====================
/// TEST CASES
/// =====================
void main() {
  group('Distance Calculation Test', () {
    test('Distance between same points should be 0', () {
      final distance = LocationUtils.calculateDistance(10, 10, 10, 10);
      expect(distance, 0);
    });

    test('Distance between two known points', () {
      final distance = LocationUtils.calculateDistance(
        11.2588, // Kozhikode
        75.7804,
        11.0168, // Malappuram approx
        76.0473,
      );

      expect(distance, greaterThan(0));
      expect(distance, lessThan(100));
    });
  });

  group('Nearest Section Algorithm Test', () {
    test('Returns nearest section correctly', () {
      final userLat = 11.25;
      final userLng = 75.77;

      final sections = [
        {
          'section_id': 'A',
          'latitude': 11.30,
          'longitude': 75.80,
        },
        {
          'section_id': 'B',
          'latitude': 11.20,
          'longitude': 75.75,
        },
        {
          'section_id': 'C',
          'latitude': 12.00,
          'longitude': 76.00,
        },
      ];

      final result = LocationUtils.findNearestSection(
        userLat,
        userLng,
        sections,
      );

      expect(result, isNotNull);
      expect(result, anyOf(['A', 'B']));
    });

    test('Handles empty list', () {
      final result = LocationUtils.findNearestSection(
        10,
        10,
        [],
      );

      expect(result, null);
    });
  });
}