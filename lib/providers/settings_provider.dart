import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  int _upcomingDays = 7;
  bool _notificationPermissionAsked = false;
  double _fabDyFraction = 0.85;
  String _fabHPosition = 'center'; // 'left' | 'center' | 'right'
  bool _onboardingCompleted = false;
  String _testCode = '';

  int get upcomingDays => _upcomingDays;
  bool get notificationPermissionAsked => _notificationPermissionAsked;
  double get fabDyFraction => _fabDyFraction;
  String get fabHPosition => _fabHPosition;
  bool get onboardingCompleted => _onboardingCompleted;
  String get testCode => _testCode;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _upcomingDays = _prefs.getInt('upcoming_days') ?? 7;
    _notificationPermissionAsked =
        _prefs.getBool('notification_permission_asked') ?? false;
    _fabDyFraction = _prefs.getDouble('fab_dy_fraction') ?? 0.85;
    _fabHPosition = _prefs.getString('fab_h_position') ?? 'center';
    _onboardingCompleted = _prefs.getBool('onboarding_completed') ?? false;
    _testCode = _prefs.getString('test_code') ?? '';
    if (_testCode.isEmpty) {
      final code = 'T-${1000 + Random().nextInt(9000)}';
      _testCode = code;
      await _prefs.setString('test_code', code);
    }
    notifyListeners();
  }

  Future<void> setUpcomingDays(int days) async {
    _upcomingDays = days;
    await _prefs.setInt('upcoming_days', days);
    notifyListeners();
  }

  Future<void> setNotificationPermissionAsked(bool value) async {
    _notificationPermissionAsked = value;
    await _prefs.setBool('notification_permission_asked', value);
    notifyListeners();
  }

  Future<void> setFabPosition(double dyFraction, String hPosition) async {
    _fabDyFraction = dyFraction;
    _fabHPosition = hPosition;
    await _prefs.setDouble('fab_dy_fraction', dyFraction);
    await _prefs.setString('fab_h_position', hPosition);
    notifyListeners();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    await _prefs.setBool('onboarding_completed', value);
    notifyListeners();
  }
}
