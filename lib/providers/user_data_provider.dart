import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<dynamic> consumerConnections = [];
  bool isLoading = false;

  Future<void> loadConsumers(String userId) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await supabase
          .from('consumer_connections')
          .select()
          .eq('user_id', userId);

      consumerConnections = response;
    } catch (e) {
      consumerConnections = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void clearData() {
    consumerConnections = [];
    notifyListeners();
  }
}