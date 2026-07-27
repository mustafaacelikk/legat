import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';

class NoteProvider extends ChangeNotifier {
  late Box<Note> _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NoteAdapter());
    }
    _box = await Hive.openBox<Note>('notes');
    notifyListeners();
  }

  List<Note> get all => _box.values.toList();

  List<Note> byProfile(String profileId) => profileId == 'all'
      ? all
      : all.where((n) => n.profileId == profileId).toList();

  Future<void> add(Note note) async {
    note.id = _uuid.v4();
    note.createdAt = DateTime.now();
    await _box.put(note.id, note);
    notifyListeners();
  }

  Future<void> update(Note note) async {
    await note.save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}