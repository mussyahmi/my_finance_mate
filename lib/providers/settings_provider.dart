import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _showNetBalance = false;
  bool _showPinnedWishlist = false;
  
  bool get showNetBalance => _showNetBalance;
  bool get showPinnedWishlist => _showPinnedWishlist;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showNetBalance = prefs.getBool('show_net_balance') ?? false;
    _showPinnedWishlist = prefs.getBool('show_pinned_wishlist') ?? false;
    notifyListeners();
  }

  Future<void> toggleShowNetBalance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_net_balance', value);
    _showNetBalance = value;
    notifyListeners();
  }

  Future<void> toggleShowPinnedWishlist(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_pinned_wishlist', value);
    _showPinnedWishlist = value;
    notifyListeners();
  }
}
