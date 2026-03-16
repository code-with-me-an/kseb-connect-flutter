import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class SectionProvider extends ChangeNotifier {

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> sections = [];

  bool loading = true;

  Future<void> loadSections() async {

    loading = true;
    notifyListeners();

    try {

      final response = await supabase
          .from('sections')
          .select('''
            section_id,
            section_code,
            name,
            division,
            subdivision,
            phone,
            address,
            latitude,
            longitude
          ''');

      sections = List<Map<String, dynamic>>.from(response)
          .where((s) => s['latitude'] != null && s['longitude'] != null)
          .map((s) {
        return {
          "id": s['section_id'],
          "code": s['section_code'],
          "name": s['name'],
          "division": s['division'],
          "subdivision": s['subdivision'],
          "phone": s['phone'],
          "address": s['address'],
          "point": LatLng(
            (s['latitude'] as num).toDouble(),
            (s['longitude'] as num).toDouble(),
          ),
        };
      }).toList();

    } catch (e) {
      debugPrint("Section load error: $e");
    }

    loading = false;
    notifyListeners();
  }
}
