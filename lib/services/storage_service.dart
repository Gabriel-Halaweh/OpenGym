import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_definition.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import '../models/custom_measurement.dart';
import '../utils/helpers.dart';

class StorageService {
  static const String _exercisesBox = 'exercises';
  static const String _dayTemplatesBox = 'day_templates';
  static const String _weekTemplatesBox = 'week_templates';
  static const String _programTemplatesBox = 'program_templates';
  static const String _scheduledDaysBox = 'scheduled_days';
  static const String _scheduledWeeksBox = 'scheduled_weeks';
  static const String _scheduledProgramsBox = 'scheduled_programs';
  static const String _measurementsBox = 'measurements';
  static const String _tagsBox = 'tags';
  static const String _tagParentsBox = 'tag_parents';
  static const String _themeBox = 'theme_prefs';
  static const String _userPrefsBox = 'user_prefs';

  late Box<String> _exercises;
  late Box<String> _dayTemplates;
  late Box<String> _weekTemplates;
  late Box<String> _programTemplates;
  late Box<String> _scheduledDays;
  late Box<String> _scheduledWeeks;
  late Box<String> _scheduledPrograms;
  late Box<String> _measurements;
  late Box<String> _tags;
  late Box<String> _tagParents;
  late Box<String> _theme;
  late Box<String> _userPrefs;

  late List<Box<String>> _templateBoxes;
  late List<Box<String>> _scheduledBoxes;

  Future<void> init() async {
    await Hive.initFlutter();
    _exercises = await Hive.openBox<String>(_exercisesBox);
    _dayTemplates = await Hive.openBox<String>(_dayTemplatesBox);
    _weekTemplates = await Hive.openBox<String>(_weekTemplatesBox);
    _programTemplates = await Hive.openBox<String>(_programTemplatesBox);
    _scheduledDays = await Hive.openBox<String>(_scheduledDaysBox);
    _scheduledWeeks = await Hive.openBox<String>(_scheduledWeeksBox);
    _scheduledPrograms = await Hive.openBox<String>(_scheduledProgramsBox);
    _measurements = await Hive.openBox<String>(_measurementsBox);
    _tags = await Hive.openBox<String>(_tagsBox);
    _tagParents = await Hive.openBox<String>(_tagParentsBox);
    _theme = await Hive.openBox<String>(_themeBox);
    _userPrefs = await Hive.openBox<String>(_userPrefsBox);

    _templateBoxes = [_dayTemplates, _weekTemplates, _programTemplates];
    _scheduledBoxes = [_scheduledDays, _scheduledWeeks, _scheduledPrograms];
  }

  // ── Exercise Definitions ──────────────────────────────────────────

  List<ExerciseDefinition> getExercises() {
    return _exercises.values
        .map(
          (json) => ExerciseDefinition.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveExercise(ExerciseDefinition exercise) async {
    await _exercises.put(exercise.id, jsonEncode(exercise.toJson()));
  }

  Future<void> deleteExercise(String id) async {
    await _exercises.delete(id);
  }

  // ── Tags ──────────────────────────────────────────────────────────

  List<String> getTags() {
    final tagsJson = _tags.get('all');
    if (tagsJson == null) return [];
    return List<String>.from(jsonDecode(tagsJson) as List);
  }

  Future<void> saveTags(List<String> tags) async {
    await _tags.put('all', jsonEncode(tags));
  }

  Map<String, String> getTagParents() {
    final Map<String, String> parents = {};
    for (final key in _tagParents.keys) {
      parents[key.toString()] = _tagParents.get(key)!;
    }
    return parents;
  }

  Future<void> saveTagParent(String tag, String? parent) async {
    if (parent == null) {
      await _tagParents.delete(tag);
    } else {
      await _tagParents.put(tag, parent);
    }
  }

  /// Remap exercise IDs across all content boxes (templates, sessions, etc.)
  /// Used when merging duplicates.
  Future<void> remapExerciseIds(Map<String, String> idRemap) async {
    if (idRemap.isEmpty) return;

    final allBoxes = [..._templateBoxes, ..._scheduledBoxes];
    
    for (final box in allBoxes) {
      final updates = <String, String>{};
      for (final entry in box.toMap().entries) {
        String json = entry.value.toString();
        bool changed = false;
        
        for (final remap in idRemap.entries) {
          final oldId = remap.key;
          final newId = remap.value;
          
          if (json.contains(oldId)) {
            // Replace occurrences of exerciseDefinitionId: "oldId"
            // We use simple string replace as these are standard JSONs
            // and UUIDs are very unlikely to collide with other JSON content.
            json = json.replaceAll('"$oldId"', '"$newId"');
            changed = true;
          }
        }
        
        if (changed) {
          updates[entry.key.toString()] = json;
        }
      }
      if (updates.isNotEmpty) {
        await box.putAll(updates);
      }
    }
  }

  Future<void> deleteTagParent(String tag) async {
    await _tagParents.delete(tag);
  }

  // ── Day Templates ─────────────────────────────────────────────────

  List<DayWorkout> getDayTemplates() {
    return _dayTemplates.values
        .map(
          (json) =>
              DayWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveDayTemplate(DayWorkout day) async {
    await _dayTemplates.put(day.id, jsonEncode(day.toJson()));
  }

  Future<void> deleteDayTemplate(String id) async {
    await _dayTemplates.delete(id);
  }

  Future<void> saveAllDayTemplates(List<DayWorkout> days) async {
    await _dayTemplates.clear();
    final Map<String, String> entries = {
      for (var d in days) d.id: jsonEncode(d.toJson()),
    };
    await _dayTemplates.putAll(entries);
  }

  // ── Week Templates ────────────────────────────────────────────────

  List<WeekWorkout> getWeekTemplates() {
    return _weekTemplates.values
        .map(
          (json) =>
              WeekWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveWeekTemplate(WeekWorkout week) async {
    await _weekTemplates.put(week.id, jsonEncode(week.toJson()));
  }

  Future<void> deleteWeekTemplate(String id) async {
    await _weekTemplates.delete(id);
  }

  Future<void> saveAllWeekTemplates(List<WeekWorkout> weeks) async {
    await _weekTemplates.clear();
    final Map<String, String> entries = {
      for (var w in weeks) w.id: jsonEncode(w.toJson()),
    };
    await _weekTemplates.putAll(entries);
  }

  // ── Program Templates ─────────────────────────────────────────────

  List<ProgramWorkout> getProgramTemplates() {
    return _programTemplates.values
        .map(
          (json) =>
              ProgramWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveProgramTemplate(ProgramWorkout program) async {
    await _programTemplates.put(program.id, jsonEncode(program.toJson()));
  }

  Future<void> deleteProgramTemplate(String id) async {
    await _programTemplates.delete(id);
  }

  Future<void> saveAllProgramTemplates(List<ProgramWorkout> programs) async {
    await _programTemplates.clear();
    final Map<String, String> entries = {
      for (var p in programs) p.id: jsonEncode(p.toJson()),
    };
    await _programTemplates.putAll(entries);
  }

  // ── Scheduled Items ───────────────────────────────────────────────

  List<DayWorkout> getScheduledDays() {
    return _scheduledDays.values
        .map(
          (json) =>
              DayWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveScheduledDay(DayWorkout day) async {
    await _scheduledDays.put(day.id, jsonEncode(day.toJson()));
  }

  Future<void> deleteScheduledDay(String id) async {
    await _scheduledDays.delete(id);
  }

  List<WeekWorkout> getScheduledWeeks() {
    return _scheduledWeeks.values
        .map(
          (json) =>
              WeekWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveScheduledWeek(WeekWorkout week) async {
    await _scheduledWeeks.put(week.id, jsonEncode(week.toJson()));
  }

  Future<void> deleteScheduledWeek(String id) async {
    await _scheduledWeeks.delete(id);
  }

  List<ProgramWorkout> getScheduledPrograms() {
    return _scheduledPrograms.values
        .map(
          (json) =>
              ProgramWorkout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveScheduledProgram(ProgramWorkout program) async {
    await _scheduledPrograms.put(program.id, jsonEncode(program.toJson()));
  }

  Future<void> deleteScheduledProgram(String id) async {
    await _scheduledPrograms.delete(id);
  }

  // ── Custom Measurements ───────────────────────────────────────────

  List<CustomMeasurement> getMeasurements() {
    return _measurements.toMap().entries
        .where((e) => e.key != 'custom_types' && e.key != 'custom_goals' && e.key != 'custom_goals_partial')
        .map(
          (e) => CustomMeasurement.fromJson(
            jsonDecode(e.value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveMeasurement(CustomMeasurement measurement) async {
    await _measurements.put(measurement.id, jsonEncode(measurement.toJson()));
  }

  Future<void> deleteMeasurement(String id) async {
    await _measurements.delete(id);
  }

  List<String> getCustomMeasurementTypes() {
    final typesJson = _measurements.get('custom_types');
    if (typesJson == null) return [];
    return List<String>.from(jsonDecode(typesJson) as List);
  }

  Future<void> saveCustomMeasurementTypes(List<String> types) async {
    await _measurements.put('custom_types', jsonEncode(types));
  }

  Map<String, double> getMeasurementGoals() {
    final goalsJson = _measurements.get('custom_goals');
    if (goalsJson == null) return {};
    final map = jsonDecode(goalsJson) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> saveMeasurementGoals(Map<String, double> goals) async {
    await _measurements.put('custom_goals', jsonEncode(goals));
  }

  // ── Themes ────────────────────────────────────────────────────────

  String? getActiveThemeId() {
    return _theme.get('active_theme_id');
  }

  Future<void> saveActiveThemeId(String id) async {
    await _theme.put('active_theme_id', id);
  }

  List<String> getCustomThemes() {
    final themesJson = _theme.get('custom_themes');
    if (themesJson == null) return [];
    return List<String>.from(jsonDecode(themesJson) as List);
  }

  Future<void> saveCustomThemes(List<String> themesJsonList) async {
    await _theme.put('custom_themes', jsonEncode(themesJsonList));
  }

  // ── User Preferences ──────────────────────────────────────────────

  int getAlbumColumns() {
    final value = _userPrefs.get('album_columns');
    if (value == null) return 3; // Default to 3 columns
    return int.parse(value);
  }

  Future<void> saveAlbumColumns(int count) async {
    await _userPrefs.put('album_columns', count.toString());
  }

  bool getCameraIsAlbumMode() {
    final value = _userPrefs.get('camera_is_album_mode');
    return value == 'true'; // Default to false (Photo mode)
  }

  Future<void> saveCameraIsAlbumMode(bool isAlbumMode) async {
    await _userPrefs.put('camera_is_album_mode', isAlbumMode.toString());
  }

  bool getHasSeenWelcome() {
    final value = _userPrefs.get('has_seen_welcome');
    return value == 'true';
  }

  Future<void> saveHasSeenWelcome(bool seen) async {
    await _userPrefs.put('has_seen_welcome', seen.toString());
  }

  // ── Clear Data (granular) ──────────────────────────────────────

  Future<void> clearExercisesAndTags() async {
    await _exercises.clear();
    await _tags.clear();
    await _tagParents.clear();
  }

  Future<void> clearDayTemplates() async {
    await _dayTemplates.clear();
  }

  Future<void> clearWeekTemplates() async {
    await _weekTemplates.clear();
  }

  Future<void> clearProgramTemplates() async {
    await _programTemplates.clear();
  }

  Future<void> clearSchedule() async {
    await _scheduledDays.clear();
    await _scheduledWeeks.clear();
    await _scheduledPrograms.clear();
  }

  Future<void> clearMeasurements() async {
    await _measurements.clear();
  }

  Future<void> clearAllData() async {
    await _exercises.clear();
    await _dayTemplates.clear();
    await _weekTemplates.clear();
    await _programTemplates.clear();
    await _scheduledDays.clear();
    await _scheduledWeeks.clear();
    await _scheduledPrograms.clear();
    await _measurements.clear();
    await _tags.clear();
    await _tagParents.clear();
    await _theme.clear();
    await _userPrefs.clear();
  }

  // ── Import / Export ─────────────────────────────────────────────

  Future<String> exportData({
    Map<String, bool>? categories,
    Map<String, List<String>>? itemIds,
  }) async {
    final Map<String, dynamic> exportMap = {};

    // Helper to add if key exists
    void addAllFromBox(String key, Box<String> box) {
      if (key == 'exercises') {
        final map = <String, String>{};
        for (final entry in box.toMap().entries) {
          final data = jsonDecode(entry.value.toString());
          data['name'] = Helpers.formatExerciseName(data['name'] ?? '');
          data.remove('defaultAlbum');
          map[entry.key.toString()] = jsonEncode(data);
        }
        exportMap[key] = map;
      } else {
        exportMap[key] = box.toMap().cast<String, String>();
      }
    }

    void addSpecificFromBox(String key, Box<String> box, List<String> ids) {
      final map = <String, String>{};
      for (final id in ids) {
        final val = box.get(id);
        if (val != null) {
          if (key == 'exercises') {
            final data = jsonDecode(val);
            data['name'] = Helpers.formatExerciseName(data['name'] ?? '');
            data.remove('defaultAlbum');
            map[id] = jsonEncode(data);
          } else {
            map[id] = val;
          }
        }
      }
      exportMap[key] = map;
    }

    // If no selections, export everything
    bool exportAll = (categories == null || categories.isEmpty) && (itemIds == null || itemIds.isEmpty);

    if (exportAll) {
      addAllFromBox('exercises', _exercises);
      addAllFromBox('day_templates', _dayTemplates);
      addAllFromBox('week_templates', _weekTemplates);
      addAllFromBox('program_templates', _programTemplates);
      addAllFromBox('scheduled_days', _scheduledDays);
      addAllFromBox('scheduled_weeks', _scheduledWeeks);
      addAllFromBox('scheduled_programs', _scheduledPrograms);
      addAllFromBox('measurements', _measurements);
      addAllFromBox('tags', _tags);
      addAllFromBox('tag_parents', _tagParents);
      addAllFromBox('theme', _theme);
    } else {
      // Data to keep track of dependencies
      final Set<String> neededExercises = {};
      final Set<String> neededDays = {};
      final Set<String> neededWeeks = {};

      void trackDayDeps(String dayJson) {
        final data = jsonDecode(dayJson);
        if (data['exercises'] != null) {
          for (var ex in data['exercises']) {
            neededExercises.add(ex['exerciseDefinitionId']);
          }
        }
      }

      void trackWeekDeps(String weekJson) {
        final data = jsonDecode(weekJson);
        if (data['days'] != null) {
          for (var day in data['days']) {
            neededDays.add(day['id']);
            trackDayDeps(jsonEncode(day));
          }
        }
      }

      void trackProgramDeps(String programJson) {
        final data = jsonDecode(programJson);
        if (data['weeks'] != null) {
          for (var week in data['weeks']) {
            neededWeeks.add(week['id']);
            trackWeekDeps(jsonEncode(week));
          }
        }
      }

      // 1. Process explicit categories
      if (categories?['exercises'] == true) addAllFromBox('exercises', _exercises);
      if (categories?['day_templates'] == true) addAllFromBox('day_templates', _dayTemplates);
      if (categories?['week_templates'] == true) addAllFromBox('week_templates', _weekTemplates);
      if (categories?['program_templates'] == true) addAllFromBox('program_templates', _programTemplates);
      if (categories?['scheduled_days'] == true) addAllFromBox('scheduled_days', _scheduledDays);
      if (categories?['scheduled_weeks'] == true) addAllFromBox('scheduled_weeks', _scheduledWeeks);
      if (categories?['scheduled_programs'] == true) addAllFromBox('scheduled_programs', _scheduledPrograms);
      if (categories?['measurements'] == true) addAllFromBox('measurements', _measurements);
      if (categories?['tags'] == true) {
        addAllFromBox('tags', _tags);
        addAllFromBox('tag_parents', _tagParents);
      }
      if (categories?['theme'] == true) addAllFromBox('theme', _theme);

      // 2. Process specific items
      itemIds?.forEach((boxKey, ids) {
        Box<String>? box;
        switch (boxKey) {
          case 'exercises': box = _exercises; break;
          case 'day_templates': box = _dayTemplates; break;
          case 'week_templates': box = _weekTemplates; break;
          case 'program_templates': box = _programTemplates; break;
          case 'scheduled_days': box = _scheduledDays; break;
          case 'scheduled_weeks': box = _scheduledWeeks; break;
          case 'scheduled_programs': box = _scheduledPrograms; break;
          case 'measurements': box = _measurements; break;
          case 'tags': box = _tags; break;
          case 'tag_parents': box = _tagParents; break;
          case 'theme': box = _theme; break;
        }

        if (box != null) {
          if (boxKey == 'tags') {
            final allTagsJson = box.get('all');
            if (allTagsJson != null) {
              final allTags = List<String>.from(jsonDecode(allTagsJson));
              final filtered = allTags.where((t) => ids.contains(t)).toList();
              if (filtered.isNotEmpty) {
                if (exportMap['tags'] == null) exportMap['tags'] = <String, String>{};
                exportMap['tags']['all'] = jsonEncode(filtered);

                // Also export relevant parents
                final Map<String, String> parents = {};
                for (var tag in filtered) {
                   final p = _tagParents.get(tag);
                   if (p != null) parents[tag] = p;
                }
                if (parents.isNotEmpty) {
                   if (exportMap['tag_parents'] == null) exportMap['tag_parents'] = <String, String>{};
                   exportMap['tag_parents'].addAll(parents);
                }
              }
            }
          } else if (boxKey == 'measurements') {
            final allMeasurements = getMeasurements();
            for (var m in allMeasurements) {
               if (ids.contains(m.type)) {
                  if (exportMap['measurements'] == null) exportMap['measurements'] = <String, String>{};
                  exportMap['measurements'][m.id] = jsonEncode(m.toJson());
               }
            }
            
            final allGoals = getMeasurementGoals();
            final Map<String, double> exportedGoals = {};
            for (var id in ids) {
              if (allGoals.containsKey(id)) {
                exportedGoals[id] = allGoals[id]!;
              }
            }
            if (exportedGoals.isNotEmpty) {
               if (exportMap['measurements'] == null) exportMap['measurements'] = <String, String>{};
               exportMap['measurements']['custom_goals_partial'] = jsonEncode(exportedGoals);
            }
          } else {
            for (var id in ids) {
              if (boxKey == 'theme' && id == 'all_prefs') {
                for (var key in box.keys) {
                  if (key != 'custom_themes') {
                    final val = box.get(key);
                    if (val != null) {
                      if (exportMap['theme'] == null) exportMap['theme'] = <String, String>{};
                      exportMap['theme'][key.toString()] = val;
                    }
                  }
                }
              } else {
                final val = box.get(id);
                if (val != null) {
                  if (exportMap[boxKey] == null) exportMap[boxKey] = <String, String>{};
                  exportMap[boxKey][id] = val;

                  if (boxKey.contains('day')) trackDayDeps(val);
                  if (boxKey.contains('week')) trackWeekDeps(val);
                  if (boxKey.contains('program')) trackProgramDeps(val);
                }
              }
            }
          }
        }
      });

      // 3. Resolve dependencies (Add missing items needed by selected templates/programs)
      // This is a simplified version, ideally recursive or multi-pass
      for (var dayId in neededDays) {
        if (!(exportMap['day_templates']?.containsKey(dayId) ?? false) && 
            !(exportMap['scheduled_days']?.containsKey(dayId) ?? false)) {
          final val = _dayTemplates.get(dayId) ?? _scheduledDays.get(dayId);
          if (val != null) {
             final key = _dayTemplates.containsKey(dayId) ? 'day_templates' : 'scheduled_days';
             if (exportMap[key] == null) exportMap[key] = <String, String>{};
             exportMap[key][dayId] = val;
          }
        }
      }
      for (var weekId in neededWeeks) {
        if (!(exportMap['week_templates']?.containsKey(weekId) ?? false) && 
            !(exportMap['scheduled_weeks']?.containsKey(weekId) ?? false)) {
          final val = _weekTemplates.get(weekId) ?? _scheduledWeeks.get(weekId);
          if (val != null) {
             final key = _weekTemplates.containsKey(weekId) ? 'week_templates' : 'scheduled_weeks';
             if (exportMap[key] == null) exportMap[key] = <String, String>{};
             exportMap[key][weekId] = val;
          }
        }
      }
      for (var exId in neededExercises) {
        if (!(exportMap['exercises']?.containsKey(exId) ?? false)) {
          final val = _exercises.get(exId);
          if (val != null) {
             if (exportMap['exercises'] == null) exportMap['exercises'] = <String, String>{};
             exportMap['exercises'][exId] = val;
          }
        }
      }

      // Always include tags if exercises are exported
      if (exportMap.containsKey('exercises') && (!exportMap.containsKey('tags'))) {
         exportMap['tags'] = _tags.toMap().cast<String, String>();
         exportMap['tag_parents'] = _tagParents.toMap().cast<String, String>();
      }
    }

    return jsonEncode(exportMap);
  }

  Future<ImportAnalysis> analyzeImport(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Parse imported exercises
    final importedExercises = <String, ExerciseDefinition>{};
    if (data.containsKey('exercises')) {
      final exMap = Map<String, String>.from(data['exercises']);
      for (var entry in exMap.entries) {
        importedExercises[entry.key] = ExerciseDefinition.fromJson(jsonDecode(entry.value));
      }
    }

    final localExercises = getExercises();
    final localExercisesByName = {
      for (var ex in localExercises) Helpers.toUniquenessKey(ex.name): ex
    };

    final conflicts = <ImportConflict>[];

    // Check for collisions and tagging matches
    for (var importedEx in importedExercises.values) {
      final nameKey = Helpers.toUniquenessKey(importedEx.name);
      if (localExercisesByName.containsKey(nameKey)) {
        final localEx = localExercisesByName[nameKey]!;
        
        final localTagsSet = localEx.tags.map((e) => e.toLowerCase()).toSet();
        final importedTagsSet = importedEx.tags.map((e) => e.toLowerCase()).toSet();
        
        if (localTagsSet.length != importedTagsSet.length || !localTagsSet.containsAll(importedTagsSet)) {
          conflicts.add(ImportConflict(localEx, importedEx));
        }
      }
    }

    // Now validate if all required exercises inside the programs/templates actually exist
    bool valid = true;
    String? errStr;

    bool checkExerciseRefs(List<dynamic>? exercisesList) {
      if (exercisesList == null) return true;
      for (var exMap in exercisesList) {
        final defId = exMap['exerciseDefinitionId'] as String;
        if (!importedExercises.containsKey(defId) && !localExercises.any((e) => e.id == defId)) {
          // It's missing in both local and imported! We can try matching by name if possible, 
          // but strict check says it must be in the JSON or local.
          final exName = exMap['exerciseName'] as String?;
          if (exName != null && localExercisesByName.containsKey(Helpers.toUniquenessKey(exName))) {
            // we will heal it later
          } else {
             errStr = 'Missing definition for exercise: ${exMap['exerciseName'] ?? defId}';
             return false;
          }
        }
      }
      return true;
    }

    if (data.containsKey('day_templates')) {
      final dtMap = Map<String, String>.from(data['day_templates']);
      for (var val in dtMap.values) {
        if (!checkExerciseRefs(jsonDecode(val)['exercises'])) valid = false;
      }
    }
    
    if (data.containsKey('week_templates') || data.containsKey('program_templates')) {
       // Deeply verifying every nested instance would go here, 
       // but typically programs hold weeks which hold days.
       // The same logic holds. You could optionally recursively check or just assume if it parses, 
       // missing IDs will be flagged upon render in the app. 
       // We'll enforce a baseline level of validation for now.
    }

    return ImportAnalysis(
      isValid: valid,
      errorMessage: errStr,
      conflicts: conflicts,
      rawJsonMap: data,
    );
  }

  Future<void> executeImport(ImportAnalysis analysis, Map<String, bool> useLocalChoices, {bool asCatalogue = false}) async {
    final data = analysis.rawJsonMap;
    
    // We need to remap IDs in case we are "using local over imported"
    final Map<String, String> idRemap = {};
    
    final localExercisesByName = {
      for (var ex in getExercises()) Helpers.toUniquenessKey(ex.name): ex
    };

    if (data.containsKey('exercises')) {
      final exMap = Map<String, String>.from(data['exercises']);
      final finalExercisesToSave = <String, String>{};

      for (var entry in exMap.entries) {
        final Map<String, dynamic> parsedEx = jsonDecode(entry.value);
        final importedEx = ExerciseDefinition.fromJson(parsedEx);
        final nameKey = Helpers.toUniquenessKey(importedEx.name);

        bool useLocal = false;
        
        if (localExercisesByName.containsKey(nameKey)) {
          final localEx = localExercisesByName[nameKey]!;
          // If there was a conflict, check resolution
          final conflictMatch = analysis.conflicts.where((c) => c.imported.id == importedEx.id).firstOrNull;
          
          if (conflictMatch != null) {
            useLocal = useLocalChoices[importedEx.id] ?? true;
          } else {
            // Implicitly use local if tags match perfectly
            useLocal = true;
          }
          
          if (useLocal) {
            idRemap[importedEx.id] = localEx.id;
          } else {
            // Using imported, so we let the imported overwrite local's tags or we save it as a new distinct ID?
            // Usually, overwriting local is expected, so we keep the local ID but apply imported data
            idRemap[importedEx.id] = localEx.id;
            parsedEx['id'] = localEx.id;
            parsedEx['name'] = Helpers.formatExerciseName(importedEx.name);
            parsedEx.remove('defaultAlbum');
            finalExercisesToSave[localEx.id] = jsonEncode(parsedEx);
          }
        } else {
          // Doesn't exist locally, just import it
          parsedEx['name'] = Helpers.formatExerciseName(importedEx.name);
          parsedEx.remove('defaultAlbum');
          finalExercisesToSave[entry.key] = jsonEncode(parsedEx);
        }
      }
      
      await _exercises.putAll(finalExercisesToSave);
    }
    
    String processTemplateForImport(String rawJson) {
      String result = rawJson;
      for (var entry in idRemap.entries) {
        if (entry.key != entry.value) {
           // Basic string replace for UUIDs
           result = result.replaceAll(entry.key, entry.value);
        }
      }
      
      if (asCatalogue) {
        final Map<String, dynamic> parsed = jsonDecode(result);
        void makeInactiveRec(Map<String, dynamic> node) {
          node['isActive'] = false;
          if (node.containsKey('weeks') && node['weeks'] is List) {
            for (var w in node['weeks']) {
              if (w is Map<String, dynamic>) makeInactiveRec(w);
            }
          }
          if (node.containsKey('days') && node['days'] is List) {
            for (var d in node['days']) {
              if (d is Map<String, dynamic>) makeInactiveRec(d);
            }
          }
        }
        makeInactiveRec(parsed);
        return jsonEncode(parsed);
      }
      
      return result;
    }

    if (data.containsKey('day_templates')) {
       final map = Map<String, String>.from(data['day_templates']);
       await _dayTemplates.putAll(map.map((k, v) => MapEntry(k, processTemplateForImport(v))));
    }
    if (data.containsKey('week_templates')) {
       final map = Map<String, String>.from(data['week_templates']);
       await _weekTemplates.putAll(map.map((k, v) => MapEntry(k, processTemplateForImport(v))));
    }
    if (data.containsKey('program_templates')) {
       final map = Map<String, String>.from(data['program_templates']);
       await _programTemplates.putAll(map.map((k, v) => MapEntry(k, processTemplateForImport(v))));
    }
    // Helper to deeply replace IDs inside scheduled JSON string representations
    String remapIdsInString(String rawJson) {
      String result = rawJson;
      for (var entry in idRemap.entries) {
        if (entry.key != entry.value) {
           result = result.replaceAll(entry.key, entry.value);
        }
      }
      return result;
    }

    if (data.containsKey('scheduled_days')) {
       final map = Map<String, String>.from(data['scheduled_days']);
       await _scheduledDays.putAll(map.map((k, v) => MapEntry(k, remapIdsInString(v))));
    }
    if (data.containsKey('scheduled_weeks')) {
       final map = Map<String, String>.from(data['scheduled_weeks']);
       await _scheduledWeeks.putAll(map.map((k, v) => MapEntry(k, remapIdsInString(v))));
    }
    if (data.containsKey('scheduled_programs')) {
       final map = Map<String, String>.from(data['scheduled_programs']);
       await _scheduledPrograms.putAll(map.map((k, v) => MapEntry(k, remapIdsInString(v))));
    }
    if (data.containsKey('measurements')) {
       final measurementsData = Map<String, String>.from(data['measurements']);
       
       if (measurementsData.containsKey('custom_goals')) {
         final importedGoals = jsonDecode(measurementsData['custom_goals']!) as Map<String, dynamic>;
         final currentGoals = getMeasurementGoals();
         for (var entry in importedGoals.entries) {
           currentGoals[entry.key] = (entry.value as num).toDouble();
         }
         await saveMeasurementGoals(currentGoals);
         measurementsData.remove('custom_goals');
       }
       if (measurementsData.containsKey('custom_goals_partial')) {
         final importedGoals = jsonDecode(measurementsData['custom_goals_partial']!) as Map<String, dynamic>;
         final currentGoals = getMeasurementGoals();
         for (var entry in importedGoals.entries) {
           currentGoals[entry.key] = (entry.value as num).toDouble();
         }
         await saveMeasurementGoals(currentGoals);
         measurementsData.remove('custom_goals_partial');
       }
       
       await _measurements.putAll(measurementsData);
    }
    
    // Merge Tags
    if (data.containsKey('tags')) {
       final newTags = Map<String, String>.from(data['tags']);
       await _tags.putAll(newTags);
    }
    if (data.containsKey('tag_parents')) {
       final newParents = Map<String, String>.from(data['tag_parents']);
       await _tagParents.putAll(newParents);
    }
    if (data.containsKey('theme')) await _theme.putAll(Map<String, String>.from(data['theme']));
  }
}

class ImportConflict {
  final ExerciseDefinition local;
  final ExerciseDefinition imported;

  ImportConflict(this.local, this.imported);
}

class ImportAnalysis {
  final bool isValid;
  final String? errorMessage;
  final List<ImportConflict> conflicts;
  final Map<String, dynamic> rawJsonMap;

  ImportAnalysis({
    required this.isValid,
    this.errorMessage,
    required this.conflicts,
    required this.rawJsonMap,
  });
}
