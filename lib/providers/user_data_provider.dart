import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<dynamic> consumerConnections = [];
  bool isLoading = false;

  String userName = "User";

  // LOAD USER NAME
  Future<void> loadUserName(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();

      userName = response['name'] ?? "User";
      notifyListeners();
    } catch (e) {
      userName = "User";
      notifyListeners();
    }
  }

  // UPDATE USER NAME
  Future<void> updateUserName(String userId, String newName) async {
    await supabase
        .from('users')
        .update({'name': newName})
        .eq('id', userId);

    userName = newName;
    notifyListeners();
  }

  // LOAD CONSUMERS
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
    userName = "User";
    notifyListeners();
  }
}