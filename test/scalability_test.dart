import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late SupabaseClient supabase;

  List<String> createdIds = [];
  List<int> failedIndexes = [];

  /// ===============================
  /// INIT
  /// ===============================
  setUpAll(() async {
    await dotenv.load(fileName: ".env");

    supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_ANON_KEY']!,
    );
  });

  /// ===============================
  /// TRACKING CODE (FROM APP)
  /// ===============================
  String generateTrackingCode() {
    final random = Random();

    String letters = String.fromCharCodes(
      List.generate(3, (_) => random.nextInt(26) + 65),
    );

    String numbers = random.nextInt(100000).toString().padLeft(5, '0');

    return letters + numbers;
  }

  /// ===============================
  /// DISTANCE
  /// ===============================
  double _deg2rad(double deg) => deg * (pi / 180);

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;

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

  /// ===============================
  /// FIND NEAREST SECTION
  /// ===============================
  Future<String?> findNearestSection(double userLat, double userLng) async {
    final sections = await supabase
        .from('sections')
        .select('section_id, latitude, longitude');

    if (sections.isEmpty) return null;

    double minDistance = double.infinity;
    String? nearestSectionId;

    for (var section in sections) {
      final lat = section['latitude'];
      final lng = section['longitude'];

      if (lat == null || lng == null) continue;

      final distance = calculateDistance(
        userLat,
        userLng,
        lat * 1.0,
        lng * 1.0,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestSectionId = section['section_id'];
      }
    }

    return nearestSectionId;
  }

  /// ===============================
  /// INSERT TEST COMPLAINT
  /// ===============================
  Future<void> submitFakeComplaint(int userIndex) async {
  try {
    final locations = [
      {"lat": 11.2855, "lng": 75.7650},
      {"lat": 11.2870, "lng": 75.7585},
      {"lat": 11.2900, "lng": 75.7705},
      {"lat": 11.2830, "lng": 75.7620},
      {"lat": 11.2890, "lng": 75.7680},
      {"lat": 11.2860, "lng": 75.7720},
    ];

    final loc = locations[userIndex % locations.length];
    final lat = loc["lat"]!;
    final lng = loc["lng"]!;

    final sectionId = await findNearestSection(lat, lng);

    print(" User $userIndex → Section: $sectionId");

    if (sectionId == null) {
      throw Exception("No section found");
    }

    final response = await supabase
        .from('complaints')
        .insert({
          'tracking_code': generateTrackingCode(),
          'user_id': 'f5dbc99e-3e21-4d46-b0c0-1b6889592bf4',
          'section_id': sectionId,
          'complaint_type': 'community',
          'category': 'line_issue',
          'description': 'Test complaint $userIndex',
          'latitude': lat,
          'longitude': lng,
          'status': 'awaiting',
        })
        .select()
        .single();

    print(" Inserted: ${response['complaint_id']}");

    createdIds.add(response['complaint_id']);
  } catch (e) {
    failedIndexes.add(userIndex);
    print(" Error for user $userIndex: $e");
  }
}

  /// ===============================
  /// TEST CASE
  /// ===============================
  test('Concurrent complaint submissions', () async {
    const totalUsers = 160;

    final stopwatch = Stopwatch()..start(); //start timing

    await Future.wait(List.generate(totalUsers, (i) => submitFakeComplaint(i)));

    stopwatch.stop(); //stop timing

    print('Total Time: ${stopwatch.elapsedMilliseconds} ms');
    print('Success: ${createdIds.length}');
    print('Failed: ${failedIndexes.length}');

    expect(createdIds.length, totalUsers);
  });

  /// ===============================
  /// CLEANUP
  /// ===============================
  tearDownAll(() async {
    if (createdIds.isNotEmpty) {
      await supabase
          .from('complaints')
          .delete()
          .inFilter('complaint_id', createdIds);

      print("Cleaned test data");
    }
  });
}
