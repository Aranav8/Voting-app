import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletState extends ChangeNotifier {
  static final WalletState _instance = WalletState._internal();
  factory WalletState() => _instance;
  WalletState._internal();

  bool _isWalletConnected = false;
  String? _walletAddress;

  bool get isWalletConnected => _isWalletConnected;
  String? get walletAddress => _walletAddress;

  Future<void> initializeWalletState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('wallet_address');
    _isWalletConnected = savedAddress != null;
    _walletAddress = savedAddress;
    notifyListeners();
  }

  Future<void> setWalletDetails(String privateKey, String walletAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('private_key', privateKey);
    await prefs.setString('wallet_address', walletAddress);
    _walletAddress = walletAddress;
    _isWalletConnected = true;
    notifyListeners();
  }

  Future<void> clearWalletDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('private_key');
    await prefs.remove('wallet_address');
    _walletAddress = null;
    _isWalletConnected = false;
    notifyListeners();
  }
}
