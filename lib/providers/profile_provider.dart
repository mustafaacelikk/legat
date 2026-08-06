// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import '../services/analytics_service.dart';

class ProfileProvider extends ChangeNotifier {
  late Box<Profile> _box;
  final _uuid = const Uuid();
  String _activeProfileId = 'all';
  late SharedPreferences _prefs;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProfileAdapter());
    }
    _box = await Hive.openBox<Profile>('profiles');
    _prefs = await SharedPreferences.getInstance();
    if (_box.isEmpty) await _addDefaults();
    notifyListeners();
  }

  Future<void> _addDefaults() async {
    final personal = Profile(
      id: 'personal', name: 'Kişisel', type: 'personal',
      colorValue: 0xFF1F3864, createdAt: DateTime.now(),
    );
    final work = Profile(
      id: 'work', name: 'İş', type: 'work',
      colorValue: 0xFF27500A, createdAt: DateTime.now(),
    );
    await _box.put(personal.id, personal);
    await _box.put(work.id, work);
  }

  List<Profile> get all {
    final list = _box.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }
  String get activeProfileId => _activeProfileId;

  void setActive(String id) {
    _activeProfileId = id;
    notifyListeners();
  }

  Future<void> add(Profile profile) async {
    profile.id = _uuid.v4();
    profile.createdAt = DateTime.now();
    await _box.put(profile.id, profile);
    await AnalyticsService.instance.logProfileCreated();
    notifyListeners();
  }

  Future<void> update(Profile profile) async {
    await profile.save();
    await AnalyticsService.instance.logProfileEdited();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await AnalyticsService.instance.logProfileDeleted();
    // Aktif profil silindiyse 'all'e dön
    if (_activeProfileId == id) {
      _activeProfileId = 'all';
    }
    // pd_ prefix'i ile kaydedilen tüm iletişim bilgilerini sil
    final detailKeys = ['firstName', 'lastName', 'email', 'phone',
                        'company', 'title', 'website', 'address', 'photoPath'];
    for (final key in detailKeys) {
      await _prefs.remove('pd_${id}_$key');
    }
    notifyListeners();
  }

  // Kişisel bilgiler — SharedPreferences'ta saklanır
  Map<String, String> getProfileDetail(String profileId) {
    final keys = ['firstName', 'lastName', 'email', 'phone', 'company',
                  'title', 'website', 'address', 'photoPath'];
    final Map<String, String> result = {};
    for (final key in keys) {
      final val = _prefs.getString('pd_${profileId}_$key');
      if (val != null) result[key] = val;
    }
    return result;
  }

  Future<void> saveProfileDetail(String profileId, Map<String, String> data) async {
    for (final entry in data.entries) {
      await _prefs.setString('pd_${profileId}_${entry.key}', entry.value);
    }
    notifyListeners();
  }
}