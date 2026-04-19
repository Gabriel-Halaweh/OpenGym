import 'package:flutter/material.dart';
import '../models/exercise_definition.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class ExerciseLibraryProvider extends ChangeNotifier {
  final StorageService _storage;
  List<ExerciseDefinition> _exercises = [];
  List<String> _tags = [];
  Map<String, String> _tagParents = {};

  ExerciseLibraryProvider(this._storage) {
    _loadAndSanitize();
  }

  List<ExerciseDefinition> get exercises => _exercises;
  List<String> get tags => _tags;
  Map<String, String> get tagParents => _tagParents;

  Future<void> _loadAndSanitize() async {
    _exercises = _storage.getExercises();
    _tags = _storage.getTags();
    _tagParents = _storage.getTagParents();
    
    // Rigorous cleanup of existing exercises
    bool changed = false;
    final seenKeys = <String, String>{}; // key -> original id
    final toDeleteRemap = <String, String>{}; // duplicate id -> existing id
    
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final formattedName = Helpers.formatExerciseName(ex.name);
      final key = Helpers.toUniquenessKey(formattedName);
      
      if (seenKeys.containsKey(key)) {
        // Duplicate found due to new rules
        toDeleteRemap[ex.id] = seenKeys[key]!;
        changed = true;
        continue;
      }
      
      seenKeys[key] = ex.id;
      if (ex.name != formattedName) {
        ex.name = formattedName;
        await _storage.saveExercise(ex);
        changed = true;
      }
    }
    
    if (toDeleteRemap.isNotEmpty) {
      for (final id in toDeleteRemap.keys) {
        _exercises.removeWhere((e) => e.id == id);
        await _storage.deleteExercise(id);
      }
      
      // Attempt to remap in all templates/scheduled items if wp is available
      // or we can add a method to StorageService to do a direct search-replace in JSONs.
      // Doing it via StorageService is safer if WorkoutProvider is not ready.
      await _storage.remapExerciseIds(toDeleteRemap);
    }

    if (changed) {
      _rebuildTags();
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Reload all data from storage (e.g. after seeding).
  Future<void> reload() async => await _loadAndSanitize();

  Future<bool> addExercise(ExerciseDefinition exercise) async {
    exercise.name = Helpers.formatExerciseName(exercise.name);
    final key = Helpers.toUniquenessKey(exercise.name);
    if (_exercises.any((e) => Helpers.toUniquenessKey(e.name) == key)) {
      return false; // Prevent duplicates
    }
    _exercises.add(exercise);
    await _storage.saveExercise(exercise);
    // Auto-add any new tags
    for (final tag in exercise.tags) {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
      }
    }
    await _storage.saveTags(_tags);
    notifyListeners();
    return true;
  }

  Future<bool> updateExercise(ExerciseDefinition exercise) async {
    exercise.name = Helpers.formatExerciseName(exercise.name);
    final key = Helpers.toUniquenessKey(exercise.name);
    
    // Check if another exercise (different ID) has the same name
    if (_exercises.any((e) => e.id != exercise.id && Helpers.toUniquenessKey(e.name) == key)) {
      return false; // Prevent duplicates on rename
    }

    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      await _storage.saveExercise(exercise);
      // Rebuild tags from all exercises
      _rebuildTags();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _storage.deleteExercise(id);
    _rebuildTags();
    notifyListeners();
  }

  void _rebuildTags() {
    final allTags = <String>{};
    // Keep existing custom tags
    allTags.addAll(_tags);
    for (final exercise in _exercises) {
      allTags.addAll(exercise.tags);
    }
    _tags = allTags.toList()..sort();
    _storage.saveTags(_tags);
  }

  Future<void> addTag(String tag) async {
    if (!_tags.contains(tag)) {
      _tags.add(tag);
      _tags.sort();
      await _storage.saveTags(_tags);
      notifyListeners();
    }
  }

  Future<void> removeTag(String tag) async {
    _tags.remove(tag);
    _tagParents.remove(tag);
    await _storage.saveTags(_tags);
    await _storage.deleteTagParent(tag);
    notifyListeners();
  }

  Future<void> setTagParent(String child, String? parent) async {
    if (parent == null) {
      _tagParents.remove(child);
    } else {
      _tagParents[child] = parent;
    }
    await _storage.saveTagParent(child, parent);
    notifyListeners();
  }

  Set<String> getDescendantTags(String tag) {
    final descendants = <String>{tag};
    bool added = true;
    while (added) {
      added = false;
      for (final child in _tags) {
        if (!descendants.contains(child) && _tagParents[child] != null) {
          if (descendants.contains(_tagParents[child])) {
            descendants.add(child);
            added = true;
          }
        }
      }
    }
    return descendants;
  }

  ExerciseDefinition? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ExerciseDefinition> searchExercises(
    String query, {
    List<String>? tagFilters,
  }) {
    var results = _exercises;
    if (query.isNotEmpty) {
      final q = Helpers.toUniquenessKey(query);
      results = results
          .where(
            (e) =>
                Helpers.toUniquenessKey(e.name).contains(q) ||
                e.tags.any((t) => Helpers.toUniquenessKey(t).contains(q)),
          )
          .toList();
    }
    if (tagFilters != null && tagFilters.isNotEmpty) {
      results = results.where((e) {
        for (final filter in tagFilters) {
          final validTags = getDescendantTags(filter);
          // If the exercise doesn't have ANY tag from this filter's lineage, drop it.
          if (!e.tags.any((t) => validTags.contains(t))) return false;
        }
        return true;
      }).toList();
    }

    // Sort results alphabetically by name
    results.sort((a, b) => a.name.compareTo(b.name));

    return results;
  }
}
