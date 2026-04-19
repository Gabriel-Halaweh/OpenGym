import 'package:flutter/material.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import '../models/custom_measurement.dart';
import '../models/exercise_set.dart';
import '../models/exercise_instance.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class WorkoutProvider extends ChangeNotifier {
  final StorageService _storage;

  // Templates
  List<DayWorkout> _dayTemplates = [];
  List<WeekWorkout> _weekTemplates = [];
  List<ProgramWorkout> _programTemplates = [];

  // Scheduled (active) items
  List<DayWorkout> _scheduledDays = [];
  List<WeekWorkout> _scheduledWeeks = [];
  List<ProgramWorkout> _scheduledPrograms = [];

  // Custom measurements
  List<CustomMeasurement> _measurements = [];
  List<String> _customMeasurementTypes = [];
  Map<String, double> _measurementGoals = {};

  WorkoutProvider(this._storage) {
    _initLoad();
  }

  void _initLoad() {
    _load();
  }

  // ── Getters ───────────────────────────────────────────────────
  List<DayWorkout> get dayTemplates => _dayTemplates;
  List<WeekWorkout> get weekTemplates => _weekTemplates;
  List<ProgramWorkout> get programTemplates => _programTemplates;

  List<DayWorkout> get activeDayTemplates => _dayTemplates.where((d) => d.isActive).toList();
  List<DayWorkout> get inactiveDayTemplates => _dayTemplates.where((d) => !d.isActive).toList();
  
  List<WeekWorkout> get activeWeekTemplates => _weekTemplates.where((w) => w.isActive).toList();
  List<WeekWorkout> get inactiveWeekTemplates => _weekTemplates.where((w) => !w.isActive).toList();

  List<ProgramWorkout> get activeProgramTemplates => _programTemplates.where((p) => p.isActive).toList();
  List<ProgramWorkout> get inactiveProgramTemplates => _programTemplates.where((p) => !p.isActive).toList();

  List<DayWorkout> get scheduledDays => _scheduledDays;
  List<WeekWorkout> get scheduledWeeks => _scheduledWeeks;
  List<ProgramWorkout> get scheduledPrograms => _scheduledPrograms;

  Future<void> _load() async {
    _dayTemplates = _storage.getDayTemplates();
    _weekTemplates = _storage.getWeekTemplates();
    _programTemplates = _storage.getProgramTemplates();
    _scheduledDays = _storage.getScheduledDays();
    _scheduledWeeks = _storage.getScheduledWeeks();
    _scheduledPrograms = _storage.getScheduledPrograms();
    _measurements = _storage.getMeasurements();
    _customMeasurementTypes = _storage.getCustomMeasurementTypes();
    _measurementGoals = _storage.getMeasurementGoals();
    
    await _sanitizeAndSaveAllNames();
    notifyListeners();
  }

  Future<void> _sanitizeAndSaveAllNames() async {
    bool changed = false;
    
    void sanitizeDay(DayWorkout day) {
      for (var ex in day.exercises) {
        final formatted = Helpers.formatExerciseName(ex.exerciseName);
        if (ex.exerciseName != formatted) {
          ex.exerciseName = formatted;
          changed = true;
        }
      }
    }

    for (var d in _dayTemplates) sanitizeDay(d);
    for (var w in _weekTemplates) {
      for (var d in w.days) sanitizeDay(d);
    }
    for (var p in _programTemplates) {
      for (var w in p.weeks) {
        for (var d in w.days) sanitizeDay(d);
      }
    }
    for (var d in _scheduledDays) sanitizeDay(d);
    for (var w in _scheduledWeeks) {
      for (var d in w.days) sanitizeDay(d);
    }
    for (var p in _scheduledPrograms) {
      for (var w in p.weeks) {
        for (var d in w.days) sanitizeDay(d);
      }
    }

    if (changed) {
      await _storage.saveAllDayTemplates(_dayTemplates);
      await _storage.saveAllWeekTemplates(_weekTemplates);
      await _storage.saveAllProgramTemplates(_programTemplates);
      
      for (var d in _scheduledDays) await _storage.saveScheduledDay(d);
      for (var w in _scheduledWeeks) await _storage.saveScheduledWeek(w);
      for (var p in _scheduledPrograms) await _storage.saveScheduledProgram(p);
    }
  }

  Future<void> reload() async {
    await _load();
  }

  // ── Clear Data (granular) ─────────────────────────────────────

  Future<void> clearDayTemplates() async {
    await _storage.clearDayTemplates();
    _dayTemplates = [];
    notifyListeners();
  }

  Future<void> clearWeekTemplates() async {
    await _storage.clearWeekTemplates();
    _weekTemplates = [];
    notifyListeners();
  }

  Future<void> clearProgramTemplates() async {
    await _storage.clearProgramTemplates();
    _programTemplates = [];
    notifyListeners();
  }

  Future<void> clearSchedule() async {
    await _storage.clearSchedule();
    _scheduledDays = [];
    _scheduledWeeks = [];
    _scheduledPrograms = [];
    notifyListeners();
  }

  Future<void> clearMeasurements() async {
    await _storage.clearMeasurements();
    _measurements = [];
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storage.clearAllData();
    _dayTemplates = [];
    _weekTemplates = [];
    _programTemplates = [];
    _scheduledDays = [];
    _scheduledWeeks = [];
    _scheduledPrograms = [];
    _measurements = [];
    notifyListeners();
  }

  // ── Day Templates ─────────────────────────────────────────────
  Future<void> saveDayTemplate(DayWorkout day) async {
    day.isTemplate = true;
    for (var ex in day.exercises) {
      ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
    }
    final idx = _dayTemplates.indexWhere((d) => d.id == day.id);
    if (idx != -1) {
      _dayTemplates[idx] = day;
    } else {
      _dayTemplates.add(day);
    }
    await _storage.saveDayTemplate(day);
    notifyListeners();
  }

  Future<void> deleteDayTemplate(String id) async {
    _dayTemplates.removeWhere((d) => d.id == id);
    await _storage.deleteDayTemplate(id);
    notifyListeners();
  }

  // ── Week Templates ────────────────────────────────────────────
  Future<void> saveWeekTemplate(WeekWorkout week) async {
    week.isTemplate = true;
    for (var d in week.days) {
      for (var ex in d.exercises) {
        ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
      }
    }
    final idx = _weekTemplates.indexWhere((w) => w.id == week.id);
    if (idx != -1) {
      _weekTemplates[idx] = week;
    } else {
      _weekTemplates.add(week);
    }
    await _storage.saveWeekTemplate(week);
    notifyListeners();
  }

  Future<void> deleteWeekTemplate(String id) async {
    _weekTemplates.removeWhere((w) => w.id == id);
    await _storage.deleteWeekTemplate(id);
    notifyListeners();
  }

  // ── Program Templates ─────────────────────────────────────────
  Future<void> saveProgramTemplate(ProgramWorkout program) async {
    program.isTemplate = true;
    for (var w in program.weeks) {
      for (var d in w.days) {
        for (var ex in d.exercises) {
          ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
        }
      }
    }
    final idx = _programTemplates.indexWhere((p) => p.id == program.id);
    if (idx != -1) {
      _programTemplates[idx] = program;
    } else {
      _programTemplates.add(program);
    }
    await _storage.saveProgramTemplate(program);
    notifyListeners();
  }

  Future<void> deleteProgramTemplate(String id) async {
    _programTemplates.removeWhere((p) => p.id == id);
    await _storage.deleteProgramTemplate(id);
    notifyListeners();
  }

  // ── Template Reordering ───────────────────────────────────────
  Future<void> reorderDayTemplates(int oldIndex, int newIndex) async {
    final active = activeDayTemplates;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    _dayTemplates = [...active, ...inactiveDayTemplates];
    await _storage.saveAllDayTemplates(_dayTemplates);
    notifyListeners();
  }

  Future<void> reorderWeekTemplates(int oldIndex, int newIndex) async {
    final active = activeWeekTemplates;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    _weekTemplates = [...active, ...inactiveWeekTemplates];
    await _storage.saveAllWeekTemplates(_weekTemplates);
    notifyListeners();
  }

  Future<void> reorderProgramTemplates(int oldIndex, int newIndex) async {
    final active = activeProgramTemplates;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    _programTemplates = [...active, ...inactiveProgramTemplates];
    await _storage.saveAllProgramTemplates(_programTemplates);
    notifyListeners();
  }

  // ── Scheduling ────────────────────────────────────────────────
  Future<void> scheduleDay(DayWorkout template, DateTime date) async {
    final copy = template.deepCopy();
    copy.isTemplate = false;
    copy.scheduledDate = date;
    copy.dayOfWeek = date.weekday % 7; // Convert to 0=Sun
    _resolvePercentageExpressions(copy);
    _scheduledDays.add(copy);
    await _storage.saveScheduledDay(copy);
    notifyListeners();
  }

  Future<void> scheduleWeek(WeekWorkout template, DateTime sunday) async {
    final copy = template.deepCopy();
    copy.isTemplate = false;
    copy.startDate = sunday;
    for (final day in copy.days) {
      if (day.dayOfWeek != null) {
        day.scheduledDate = sunday.add(Duration(days: day.dayOfWeek!));
        day.isTemplate = false;
      }
      _resolvePercentageExpressions(day);
    }
    _scheduledWeeks.add(copy);
    await _storage.saveScheduledWeek(copy);
    notifyListeners();
  }

  Future<void> scheduleProgram(
    ProgramWorkout template,
    DateTime startSunday,
  ) async {
    final copy = template.deepCopy();
    copy.isTemplate = false;
    copy.startDate = startSunday;
    for (int i = 0; i < copy.weeks.length; i++) {
      final weekStart = startSunday.add(Duration(days: i * 7));
      copy.weeks[i].startDate = weekStart;
      copy.weeks[i].isTemplate = false;
      for (final day in copy.weeks[i].days) {
        if (day.dayOfWeek != null) {
          day.scheduledDate = weekStart.add(Duration(days: day.dayOfWeek!));
          day.isTemplate = false;
        }
        _resolvePercentageExpressions(day);
      }
    }
    _scheduledPrograms.add(copy);
    await _storage.saveScheduledProgram(copy);
    notifyListeners();
  }

  Future<void> removeScheduledDay(String id) async {
    _scheduledDays.removeWhere((d) => d.id == id);
    await _storage.deleteScheduledDay(id);
    notifyListeners();
  }

  Future<void> removeScheduledWeek(String id) async {
    _scheduledWeeks.removeWhere((w) => w.id == id);
    await _storage.deleteScheduledWeek(id);
    notifyListeners();
  }

  Future<void> removeScheduledProgram(String id) async {
    _scheduledPrograms.removeWhere((p) => p.id == id);
    await _storage.deleteScheduledProgram(id);
    notifyListeners();
  }

  /// Remove a day from its parent week/program
  Future<void> removeScheduledDayFromParent(
    String dayId,
    String? parentType,
    String? parentId,
  ) async {
    if (parentType == null) {
      // Standalone day
      await removeScheduledDay(dayId);
      return;
    }
    if (parentType == 'week' && parentId != null) {
      final week = _scheduledWeeks.where((w) => w.id == parentId).firstOrNull;
      if (week != null) {
        week.days.removeWhere((d) => d.id == dayId);
        // Call saveScheduledWeek instead of direct storage to trigger completion logic
        await saveScheduledWeek(week);
      }
    } else if (parentType == 'program' && parentId != null) {
      final program = _scheduledPrograms
          .where((p) => p.id == parentId)
          .firstOrNull;
      if (program != null) {
        for (final week in program.weeks) {
          week.days.removeWhere((d) => d.id == dayId);
        }
        // Call saveScheduledProgram instead of direct storage to trigger completion logic
        await saveScheduledProgram(program);
      }
    }
  }

  // ── Percentage Resolution ──────────────────────────────────────

  void _resolvePercentageExpressions(DayWorkout day) {
    for (final ex in day.exercises) {
      if (ex.usePercentage) {
        final ref = getExerciseReferenceWeight(ex.exerciseDefinitionId);
        if (ref != null && ref > 0) {
          for (final set in ex.sets) {
            // Source of truth for the percentage: use set.percent if available, 
            // otherwise use current value (assuming it was entered as a % in the editor)
            final sourcePercent = set.percent ?? (ex.isWeightedTimed ? set.weight : set.value);
            
            if (sourcePercent != null && sourcePercent > 0) {
              set.percent = sourcePercent; // Ensure it's stored
              final flatWeight = (sourcePercent / 100) * ref;
              
              if (ex.isWeightedTimed) {
                set.weight = flatWeight.roundToDouble();
              } else {
                set.value = flatWeight.roundToDouble();
              }
            }
          }
        }
      }
    }
  }

  /// Recalculates weights for any incomplete exercise that uses the percentage toggle.
  /// This ensures that as the user's maxes increase, their prescribed work updates.
  void recalculateIncompletePercentages(DayWorkout day) {
    bool changed = false;
    for (final ex in day.exercises) {
      // Only recalculate if the exercise is NOT completed AND uses percentage
      if (ex.usePercentage && !ex.isCompleted) {
        final ref = getExerciseReferenceWeight(ex.exerciseDefinitionId);
        if (ref != null && ref > 0) {
          for (final set in ex.sets) {
            // If the set itself is already checked, don't recalculate it? 
            // The user said "If the exercise is complete, it should not recalculate".
            // If the exercise is incomplete, we should probably recalculate all sets that aren't checked.
            if (!set.isChecked && set.percent != null && set.percent! > 0) {
              final flatWeight = (set.percent! / 100) * ref;
              if (ex.isWeightedTimed) {
                if (set.weight != flatWeight.roundToDouble()) {
                  set.weight = flatWeight.roundToDouble();
                  changed = true;
                }
              } else {
                if (set.value != flatWeight.roundToDouble()) {
                  set.value = flatWeight.roundToDouble();
                  changed = true;
                }
              }
            }
          }
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Get reference weight for an exercise: absolute maximum weight done across all sessions
  /// Scanning ALL scheduled items (not just completed logs) ensures that PRs set in the CURRENT 
  /// session immediately update other exercises in that same session.
  double? getExerciseReferenceWeight(String exerciseDefinitionId) {
    double maxWeight = 0;

    void processDay(DayWorkout day) {
      for (final ex in day.exercises) {
        if (ex.exerciseDefinitionId == exerciseDefinitionId) {
          for (final s in ex.sets) {
            if (s.isChecked) {
              double w = 0;
              if (ex.isTimed) {
                if (ex.isWeightedTimed) {
                  w = s.weight ?? 0.0;
                }
              } else {
                w = s.value ?? 0.0;
              }
              if (w > maxWeight) maxWeight = w;
            }
          }
        }
      }
    }

    // StandardStandalone days
    for (final day in _scheduledDays) {
      processDay(day);
    }
    // Recurring weeks
    for (final week in _scheduledWeeks) {
      for (final day in week.days) {
        processDay(day);
      }
    }
    // Programs
    for (final prog in _scheduledPrograms) {
      for (final week in prog.weeks) {
        for (final day in week.days) {
          processDay(day);
        }
      }
    }

    if (maxWeight == 0) return null;
    return maxWeight;
  }

  /// Get concise and helpful statistics for an exercise
  Map<String, String> getExerciseStats(
    String exerciseDefinitionId, {
    bool? isTimed,
    bool? isWeightedTimed,
  }) {
    double maxWeight = 0;
    int totalReps = 0;
    double totalVolume = 0;

    final sessionMaxes = <double>[];
    final sessionVolumes = <double>[];

    final bool modeTimed = isTimed ?? false;
    final bool modeWeightedTimed = isWeightedTimed ?? false;

    void processDay(DayWorkout day) {
      if (!day.isCompleted || day.completedDate == null) return;
      double currentSessionMax = 0;
      double currentSessionVol = 0;
      bool hasTargetEx = false;

      for (final ex in day.exercises) {
        if (ex.exerciseDefinitionId == exerciseDefinitionId) {
          for (final s in ex.sets) {
            if (isSetApplicable(ex, s, modeTimed, modeWeightedTimed)) {
              hasTargetEx = true;
              double weight = ex.isWeightedTimed ? (s.weight ?? 0.0) : (s.value ?? 0.0);
              double time = (s.timeSeconds ?? (s.value?.toInt() ?? 0)).toDouble();
              int reps = s.reps ?? 0;

              double vol = 0;
              double peak = 0;

              if (modeTimed && modeWeightedTimed) {
                vol = weight * time * reps;
                peak = weight;
              } else if (modeTimed) {
                vol = time;
                peak = time;
              } else {
                vol = weight * reps;
                peak = weight;
                totalReps += reps;
              }

              currentSessionVol += vol;
              if (peak > currentSessionMax) currentSessionMax = peak;
              
              if (peak > maxWeight) maxWeight = peak;
            }
          }
        }
      }

      if (hasTargetEx && currentSessionVol > 0) {
        sessionMaxes.add(currentSessionMax);
        sessionVolumes.add(currentSessionVol);
        totalVolume += currentSessionVol;
      }
    }

    // Iterate through all sources
    for (final day in _scheduledDays) {
      processDay(day);
    }
    for (final week in _scheduledWeeks) {
      for (final day in week.days) {
        processDay(day);
      }
    }
    for (final prog in _scheduledPrograms) {
      for (final week in prog.weeks) {
        for (final day in week.days) {
          processDay(day);
        }
      }
    }
    if (sessionMaxes.isEmpty) return {};

    final avgMax = sessionMaxes.reduce((a, b) => a + b) / sessionMaxes.length;
    final avgVol = sessionVolumes.reduce((a, b) => a + b) / sessionVolumes.length;

    // Use isTimed if we have any instance to refer to, or the provided flag
    final bool timedMode = isTimed ?? false;
    final bool weightedTimedMode = isWeightedTimed ?? false;

    return {
      (timedMode && !weightedTimedMode) ? 'Max Time' : 'Max': 
          (timedMode && !weightedTimedMode) ? Helpers.formatDurationLong(maxWeight.toInt()) : Helpers.formatCompactNumber(maxWeight),
      (timedMode && !weightedTimedMode) ? 'Avg Max Time' : 'Avg Max': 
          (timedMode && !weightedTimedMode) ? Helpers.formatDurationLong(avgMax.toInt()) : Helpers.formatCompactNumber(avgMax),
      (timedMode && !weightedTimedMode) ? 'Total Time' : 'Total Volume': 
          (timedMode && !weightedTimedMode) ? Helpers.formatDurationLong(totalVolume.toInt()) : Helpers.formatCompactNumber(totalVolume),
      (timedMode && !weightedTimedMode) ? 'Avg Time' : 'Avg Volume': 
          (timedMode && !weightedTimedMode) ? Helpers.formatDurationLong(avgVol.toInt()) : Helpers.formatCompactNumber(avgVol),
      'Total Reps': totalReps.toString(),
      'Sessions': sessionMaxes.length.toString(),
    };
  }

  /// 0: No data for any variant, 1: Data for other variants, 2: Data for this specific variant
  int getExerciseDataLevel(String id, bool isTimed, bool isWeightedTimed) {
    if (getExerciseStats(id, isTimed: isTimed, isWeightedTimed: isWeightedTimed).isNotEmpty) return 2;
    
    // Check others
    if (getExerciseStats(id, isTimed: true, isWeightedTimed: true).isNotEmpty) return 1;
    if (getExerciseStats(id, isTimed: true, isWeightedTimed: false).isNotEmpty) return 1;
    if (getExerciseStats(id, isTimed: false, isWeightedTimed: false).isNotEmpty) return 1;
    
    return 0;
  }

  /// Get the total volume for the last N sessions of an exercise (chronological order)
  /// Get the full data (sets, weight, reps) for the last N sessions of an exercise
  List<ExerciseInstance> getExerciseFullHistory(
    String exerciseDefinitionId, {
    bool? isTimed,
    bool? isWeightedTimed,
    int limit = 7,
  }) {
    List<ExerciseInstance> history = [];
    final bool modeTimed = isTimed ?? false;
    final bool modeWeightedTimed = isWeightedTimed ?? false;

    // allCompletedItems is newest first
    for (final log in allCompletedItems) {
      if (log['type'] == 'day') {
        final day = log['item'] as DayWorkout;
        for (final ex in day.exercises) {
          if (ex.exerciseDefinitionId == exerciseDefinitionId) {
            // Only add if it has sets applicable to this mode
            if (ex.sets.any((s) => isSetApplicable(ex, s, modeTimed, modeWeightedTimed))) {
              history.add(ex);
              break;
            }
          }
        }
      }
      if (history.length >= limit) break;
    }
    return history.reversed.toList();
  }

  bool isSetApplicable(ExerciseInstance ex, ExerciseSet s, bool modeTimed, bool modeWeightedTimed) {
    if (!s.isChecked) return false;
    
    if (modeTimed && modeWeightedTimed) {
      // Weight-Time View: Must be a weighted-timed exercise AND have both weight and time
      if (!ex.isWeightedTimed) return false;
      double weight = s.weight ?? 0;
      double time = (s.timeSeconds ?? s.value ?? 0).toDouble();
      return weight > 0 && time > 0;
    } else if (modeTimed) {
      // Time View: can be plain timed OR weighted-timed, but must have duration
      double time = (s.timeSeconds ?? s.value ?? 0).toDouble();
      return time > 0;
    } else {
      // Weight View: can be plain weight OR weighted-timed, but must have weight AND reps
      if (ex.isTimed && !ex.isWeightedTimed) return false; // Pure timed has no weight context
      double weight = ex.isWeightedTimed ? (s.weight ?? 0) : (s.value ?? 0);
      int reps = s.reps ?? 0;
      return weight >= 0 && reps > 0;
    }
  }

  /// Get the total volume for the last N sessions of an exercise (chronological order)
  List<double> getExerciseVolumeHistory(
    String exerciseDefinitionId, {
    required bool isTimed,
    required bool isWeightedTimed,
    int limit = 7,
  }) {
    final history = getExerciseFullHistory(
      exerciseDefinitionId,
      isTimed: isTimed,
      isWeightedTimed: isWeightedTimed,
      limit: limit,
    );
    return history.map((ex) {
      double sessionVolume = 0;
      for (final s in ex.sets) {
        if (s.isChecked) {
          double weight = 0;
          double reps = (s.reps ?? 1).toDouble();
          double time = (s.value ?? 0.0);

          if (ex.isTimed && ex.isWeightedTimed) {
            weight = s.weight ?? 0.0;
            sessionVolume += weight * time * reps;
          } else if (ex.isTimed) {
            sessionVolume += time;
          } else {
            weight = s.value ?? 0.0;
            sessionVolume += weight * reps;
          }
        }
      }
      return sessionVolume;
    }).toList();
  }

  // ── Save Active Progress ──────────────────────────────────────
  Future<void> saveScheduledDay(DayWorkout day) async {
    for (var ex in day.exercises) {
      ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
    }
    final idx = _scheduledDays.indexWhere((d) => d.id == day.id);
    if (idx != -1) {
      _scheduledDays[idx] = day;
    } else {
      _scheduledDays.add(day);
    }

    // Check for completion-driven date resets
    if (day.isCompleted) {
      // If completed but no date yet, set it to now
      day.completedDate ??= DateTime.now();
    } else {
      // If no longer completed, clear the date
      day.completedDate = null;
    }

    await _storage.saveScheduledDay(day);
    notifyListeners();
  }

  Future<void> saveScheduledWeek(WeekWorkout week) async {
    for (var d in week.days) {
      for (var ex in d.exercises) {
        ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
      }
    }
    final idx = _scheduledWeeks.indexWhere((w) => w.id == week.id);
    if (idx != -1) {
      _scheduledWeeks[idx] = week;
    } else {
      // It's a newly scheduled one-shot draft, days need scheduledDate
      if (week.startDate != null) {
        for (final day in week.days) {
          if (day.dayOfWeek != null && day.scheduledDate == null) {
            day.scheduledDate = week.startDate!.add(
              Duration(days: day.dayOfWeek!),
            );
          }
        }
      }
      _scheduledWeeks.add(week);
    }

    if (week.isCompleted && week.completedDate == null) {
      DateTime? latestDate;
      for (final day in week.days) {
        if (day.isCompleted && day.scheduledDate != null) {
          if (latestDate == null || day.scheduledDate!.isAfter(latestDate)) {
            latestDate = day.scheduledDate;
          }
        }
      }
      week.completedDate = latestDate ?? week.startDate ?? DateTime.now();
    } else if (!week.isCompleted && week.completedDate != null) {
      week.completedDate = null;
    }

    // Update dates for child days
    for (final day in week.days) {
      if (day.isCompleted && day.completedDate == null) {
        day.completedDate =
            day.scheduledDate ?? week.startDate ?? DateTime.now();
      } else if (!day.isCompleted && day.completedDate != null) {
        day.completedDate = null;
      }
    }

    await _storage.saveScheduledWeek(week);
    notifyListeners();
  }

  Future<void> saveScheduledProgram(ProgramWorkout program) async {
    for (var w in program.weeks) {
      for (var d in w.days) {
        for (var ex in d.exercises) {
          ex.exerciseName = Helpers.formatExerciseName(ex.exerciseName);
        }
      }
    }
    final idx = _scheduledPrograms.indexWhere((p) => p.id == program.id);
    if (idx != -1) {
      _scheduledPrograms[idx] = program;
    } else {
      // It's a newly scheduled one-shot draft, days need scheduledDate
      if (program.startDate != null) {
        for (int i = 0; i < program.weeks.length; i++) {
          final weekStart = program.startDate!.add(Duration(days: i * 7));
          program.weeks[i].startDate = weekStart;
          for (final day in program.weeks[i].days) {
            if (day.dayOfWeek != null && day.scheduledDate == null) {
              day.scheduledDate = weekStart.add(
                Duration(days: day.dayOfWeek!),
              );
            }
          }
        }
      }
      _scheduledPrograms.add(program);
    }

    if (program.isCompleted) {
      DateTime? latestDate;
      for (final week in program.weeks) {
        for (final day in week.days) {
          if (day.isCompleted && day.completedDate != null) {
            if (latestDate == null || day.completedDate!.isAfter(latestDate)) {
              latestDate = day.completedDate;
            }
          }
        }
      }
      // Always sync the program's completion date to the latest day finished
      program.completedDate = latestDate ?? program.startDate ?? DateTime.now();
    } else {
      program.completedDate = null;
    }

    // Update dates for child weeks and days
    for (final week in program.weeks) {
      if (week.isCompleted) {
        DateTime? latestDate;
        for (final day in week.days) {
          if (day.isCompleted && day.completedDate != null) {
            if (latestDate == null || day.completedDate!.isAfter(latestDate)) {
              latestDate = day.completedDate;
            }
          }
        }
        week.completedDate =
            latestDate ?? week.startDate ?? program.startDate ?? DateTime.now();
      } else {
        week.completedDate = null;
      }

      for (final day in week.days) {
        if (day.isCompleted && day.completedDate == null) {
          day.completedDate =
              day.scheduledDate ??
              week.startDate ??
              program.startDate ??
              DateTime.now();
        } else if (!day.isCompleted && day.completedDate != null) {
          day.completedDate = null;
        }
      }
    }

    await _storage.saveScheduledProgram(program);
    notifyListeners();
  }

  // ── Completion & Logging ──────────────────────────────────────

  // ── Query Helpers ─────────────────────────────────────────────

  /// Dynamically get all completed workouts (days, weeks, programs) to serve as logs
  List<Map<String, dynamic>> get allCompletedItems {
    final items = <Map<String, dynamic>>[];

    // Add completed days
    for (final day in _scheduledDays) {
      if (day.isCompleted && day.completedDate != null) {
        items.add({'type': 'day', 'item': day, 'date': day.completedDate});
      }
    }

    // Add completed weeks and their completed child days
    for (final week in _scheduledWeeks) {
      if (week.isCompleted && week.completedDate != null) {
        items.add({'type': 'week', 'item': week, 'date': week.completedDate});
      }
      for (final day in week.days) {
        if (day.isCompleted && day.completedDate != null) {
          items.add({
            'type': 'day',
            'item': day,
            'date': day.completedDate,
            'parentType': 'week',
            'parentId': week.id,
            'parentName': week.title,
          });
        }
      }
    }

    // Add completed programs, their weeks, and their days
    for (final prog in _scheduledPrograms) {
      if (prog.isCompleted && prog.completedDate != null) {
        items.add({
          'type': 'program',
          'item': prog,
          'date': prog.completedDate,
        });
      }
      for (final week in prog.weeks) {
        if (week.isCompleted && week.completedDate != null) {
          items.add({
            'type': 'week',
            'item': week,
            'date': week.completedDate,
            'parentType': 'program',
            'parentId': prog.id,
            'parentName': prog.title,
          });
        }
        for (final day in week.days) {
          if (day.isCompleted && day.completedDate != null) {
            items.add({
              'type': 'day',
              'item': day,
              'date': day.completedDate,
              'parentType': 'program',
              'parentId': prog.id,
              'parentName': '${prog.title} - ${week.title}',
            });
          }
        }
      }
    }

    // Sort descending by completion date, then by hierarchy weight
    items.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;

      final dateCmp = DateTime(
        dateB.year,
        dateB.month,
        dateB.day,
      ).compareTo(DateTime(dateA.year, dateA.month, dateA.day));

      if (dateCmp != 0) return dateCmp;

      int weight(String type) {
        if (type == 'program') return 3;
        if (type == 'week') return 2;
        if (type == 'day') return 1;
        return 0;
      }

      return weight(b['type'] as String).compareTo(weight(a['type'] as String));
    });
    return items;
  }

  /// Get all items scheduled for a specific date
  List<Map<String, dynamic>> getItemsForDate(DateTime date) {
    final items = <Map<String, dynamic>>[];

    // Standalone scheduled days
    for (final day in _scheduledDays) {
      if (day.scheduledDate != null && _isSameDay(day.scheduledDate!, date)) {
        items.add({
          'type': 'day',
          'item': day,
          'parentType': null,
          'parentId': null,
          'parentName': null,
          'parentProgress': null,
          'weekName': null,
          'weekProgress': null,
        });
      }
    }

    // Days from scheduled weeks
    for (final week in _scheduledWeeks) {
      for (final day in week.days) {
        if (day.scheduledDate != null && _isSameDay(day.scheduledDate!, date)) {
          items.add({
            'type': 'day',
            'item': day,
            'parentType': 'week',
            'parentId': week.id,
            'parentName': week.displayTitle,
            'parentProgress': week.progress,
            'weekName': null,
            'weekProgress': null,
          });
        }
      }
    }

    // Days from scheduled programs
    for (final program in _scheduledPrograms) {
      for (final week in program.weeks) {
        for (final day in week.days) {
          if (day.scheduledDate != null &&
              _isSameDay(day.scheduledDate!, date)) {
            items.add({
              'type': 'day',
              'item': day,
              'parentType': 'program',
              'parentId': program.id,
              'parentName': program.displayTitle,
              'parentProgress': program.progress,
              'weekName': week.displayTitle,
              'weekProgress': week.progress,
            });
          }
        }
      }
    }

    return items;
  }

  /// Get calendar event markers for a date range
  Map<DateTime, List<String>> getEventMarkers(DateTime start, DateTime end) {
    final markers = <DateTime, List<String>>{};

    void addMarker(DateTime date, String status) {
      final key = DateTime(date.year, date.month, date.day);
      markers.putIfAbsent(key, () => []);
      markers[key]!.add(status);
    }

    // Check scheduled days
    for (final day in _scheduledDays) {
      if (day.scheduledDate != null && !day.isHidden) {
        final d = day.scheduledDate!;
        final startBound = DateTime(start.year, start.month, start.day);
        final nextDayAfterEnd = DateTime(
          end.year,
          end.month,
          end.day,
        ).add(const Duration(days: 1));
        if (!d.isBefore(startBound) && d.isBefore(nextDayAfterEnd)) {
          addMarker(
            d,
            day.isCompleted
                ? 'completed'
                : (d.isBefore(DateTime.now()) && !day.isCompleted)
                ? 'missed'
                : 'scheduled',
          );
        }
      }
    }

    // Check weeks
    for (final week in _scheduledWeeks) {
      for (final day in week.days) {
        if (day.scheduledDate != null && !day.isHidden) {
          final d = day.scheduledDate!;
          final startBound = DateTime(start.year, start.month, start.day);
          final endBound = DateTime(
            end.year,
            end.month,
            end.day,
            23,
            59,
            59,
            999,
          );
          if (!d.isBefore(startBound) && !d.isAfter(endBound)) {
            addMarker(
              d,
              day.isCompleted
                  ? 'completed'
                  : (d.isBefore(DateTime.now()) && !day.isCompleted)
                  ? 'missed'
                  : 'scheduled',
            );
          }
        }
      }
    }

    // Check programs
    for (final program in _scheduledPrograms) {
      for (final week in program.weeks) {
        for (final day in week.days) {
          if (day.scheduledDate != null && !day.isHidden) {
            final d = day.scheduledDate!;
            final startBound = DateTime(start.year, start.month, start.day);
            final endBound = DateTime(
              end.year,
              end.month,
              end.day,
              23,
              59,
              59,
              999,
            );
            if (!d.isBefore(startBound) && !d.isAfter(endBound)) {
              addMarker(
                d,
                day.isCompleted
                    ? 'completed'
                    : (d.isBefore(DateTime.now()) && !day.isCompleted)
                    ? 'missed'
                    : 'scheduled',
              );
            }
          }
        }
      }
    }

    return markers;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Find parent containers for a day
  WeekWorkout? findWeekContainingDay(String dayId) {
    for (final week in _scheduledWeeks) {
      for (final day in week.days) {
        if (day.id == dayId) return week;
      }
    }
    for (final program in _scheduledPrograms) {
      for (final week in program.weeks) {
        for (final day in week.days) {
          if (day.id == dayId) return week;
        }
      }
    }
    return null;
  }

  ProgramWorkout? findProgramContainingDay(String dayId) {
    for (final program in _scheduledPrograms) {
      for (final week in program.weeks) {
        for (final day in week.days) {
          if (day.id == dayId) return program;
        }
      }
    }
    return null;
  }

  // ── Custom Measurements ────────────────────────────────────────
  List<CustomMeasurement> get measurements => _measurements;

  List<CustomMeasurement> getMeasurementsByType(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _measurements.where((m) {
      if (m.type != type) return false;
      if (m.date.isBefore(
        DateTime(startDate.year, startDate.month, startDate.day),
      )) {
        return false;
      }
      if (m.date.isAfter(
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      )) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Set<String> get measurementTypes {
    return {..._measurements.map((m) => m.type), ..._customMeasurementTypes};
  }

  Future<void> addCustomMeasurementType(String type) async {
    if (!_customMeasurementTypes.contains(type)) {
      _customMeasurementTypes.add(type);
      await _storage.saveCustomMeasurementTypes(_customMeasurementTypes);
      notifyListeners();
    }
  }

  double? getMeasurementGoal(String type) => _measurementGoals[type];

  Future<void> setMeasurementGoal(String type, double goal) async {
    _measurementGoals[type] = goal;
    await _storage.saveMeasurementGoals(_measurementGoals);
    notifyListeners();
  }

  Future<void> clearMeasurementGoal(String type) async {
    if (_measurementGoals.containsKey(type)) {
      _measurementGoals.remove(type);
      await _storage.saveMeasurementGoals(_measurementGoals);
      notifyListeners();
    }
  }

  Future<void> saveMeasurement(CustomMeasurement measurement) async {
    // If unit changed, update all past measurements of this type
    if (measurement.unit != null) {
      final oldUnit = _measurements
          .firstWhere(
            (m) => m.type == measurement.type && m.unit != null,
            orElse: () => measurement,
          )
          .unit;

      if (oldUnit != null && oldUnit != measurement.unit) {
        // Bulk update
        for (var i = 0; i < _measurements.length; i++) {
          if (_measurements[i].type == measurement.type) {
            _measurements[i] = CustomMeasurement(
              id: _measurements[i].id,
              date: _measurements[i].date,
              type: _measurements[i].type,
              value: _measurements[i].value,
              unit: measurement.unit,
            );
            await _storage.saveMeasurement(_measurements[i]);
          }
        }
      }
    }

    _measurements.add(measurement);
    await _storage.saveMeasurement(measurement);

    // Also ensure the type is in custom types list if it's not a default one
    final defaultTypes = [
      'weight',
      'body_fat',
      'waist',
      'chest',
      'arms',
      'thighs',
    ];
    if (!defaultTypes.contains(measurement.type) &&
        !_customMeasurementTypes.contains(measurement.type)) {
      _customMeasurementTypes.add(measurement.type);
      await _storage.saveCustomMeasurementTypes(_customMeasurementTypes);
    }

    notifyListeners();
  }

  Future<void> deleteMeasurement(String id) async {
    _measurements.removeWhere((m) => m.id == id);
    await _storage.deleteMeasurement(id);
    notifyListeners();
  }

  Future<void> updateMeasurement(CustomMeasurement measurement) async {
    final idx = _measurements.indexWhere((m) => m.id == measurement.id);
    if (idx != -1) {
      _measurements[idx] = measurement;
    }
    await _storage.saveMeasurement(measurement);
    notifyListeners();
  }

  Future<void> deleteMeasurementsByType(String type) async {
    final toDelete = _measurements.where((m) => m.type == type).toList();
    for (final m in toDelete) {
      await _storage.deleteMeasurement(m.id);
    }
    _measurements.removeWhere((m) => m.type == type);

    if (_customMeasurementTypes.contains(type)) {
      _customMeasurementTypes.remove(type);
      await _storage.saveCustomMeasurementTypes(_customMeasurementTypes);
    }

    notifyListeners();
  }

  // ── Custom Measurements ──────────────────────────────────────
}
