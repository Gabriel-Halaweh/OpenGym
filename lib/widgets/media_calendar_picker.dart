import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/media_item.dart';
import '../utils/constants.dart';

class MediaCalendarPicker extends StatefulWidget {
  final List<MediaItem> items;
  final bool isRangeSelection;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? initialSelectedDate;
  final String? initialActiveSelector; // 'start' or 'end'

  const MediaCalendarPicker({
    super.key,
    required this.items,
    this.isRangeSelection = false,
    this.initialStartDate,
    this.initialEndDate,
    this.initialSelectedDate,
    this.initialActiveSelector,
  });

  static Future<DateTimeRange?> showRangePicker(
    BuildContext context,
    List<MediaItem> items, {
    DateTimeRange? initialRange,
  }) async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        backgroundColor: AppConstants.bgCard,
        child: SingleChildScrollView(
          child: MediaCalendarPicker(
            items: items,
            isRangeSelection: true,
            initialStartDate: initialRange?.start,
            initialEndDate: initialRange?.end,
            initialActiveSelector: 'start',
          ),
        ),
      ),
    );
    return result;
  }

  static Future<DateTimeRange?> showRangePickerWithInitialSelector(
    BuildContext context,
    List<MediaItem> items,
    String initialSelector, {
    DateTimeRange? initialRange,
  }) async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        backgroundColor: AppConstants.bgCard,
        child: SingleChildScrollView(
          child: MediaCalendarPicker(
            items: items,
            isRangeSelection: true,
            initialStartDate: initialRange?.start,
            initialEndDate: initialRange?.end,
            initialActiveSelector: initialSelector,
          ),
        ),
      ),
    );
    return result;
  }

  static Future<DateTime?> showSinglePicker(
    BuildContext context,
    List<MediaItem> items, {
    DateTime? initialDate,
  }) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        backgroundColor: AppConstants.bgCard,
        child: SingleChildScrollView(
          child: MediaCalendarPicker(
            items: items,
            isRangeSelection: false,
            initialSelectedDate: initialDate,
          ),
        ),
      ),
    );
    return result;
  }

  @override
  State<MediaCalendarPicker> createState() => _MediaCalendarPickerState();
}

class _MediaCalendarPickerState extends State<MediaCalendarPicker> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  late String _activeSelector;

  late Map<DateTime, List<MediaItem>> _eventsMap;

  @override
  void initState() {
    super.initState();
    _focusedDay =
        widget.initialSelectedDate ?? widget.initialStartDate ?? DateTime.now();
    _selectedDay = widget.initialSelectedDate;
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    if (widget.isRangeSelection) {
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
      _activeSelector = widget.initialActiveSelector ?? 'start';
    } else {
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
      _activeSelector = 'start';
    }

    _eventsMap = {};
    for (var item in widget.items) {
      final key = DateTime(
        item.dateTaken.year,
        item.dateTaken.month,
        item.dateTaken.day,
      );
      if (_eventsMap[key] == null) {
        _eventsMap[key] = [];
      }
      _eventsMap[key]!.add(item);
    }
  }

  List<MediaItem> _getEventsForDay(DateTime day) {
    return _eventsMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!widget.isRangeSelection) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    } else {
      setState(() {
        _focusedDay = focusedDay;
        if (_activeSelector == 'start') {
          _rangeStart = selectedDay;
          if (_rangeEnd != null && _rangeStart!.isAfter(_rangeEnd!)) {
            // Auto swap end date to current start
            final temp = _rangeEnd;
            _rangeEnd = _rangeStart;
            _rangeStart = temp;
            _activeSelector =
                'end'; // Optionally switch active to end after swap
          } else if (_rangeEnd == null) {
            _activeSelector = 'end'; // Auto switch to empty bound
          }
        } else {
          _rangeEnd = selectedDay;
          if (_rangeStart != null && _rangeEnd!.isBefore(_rangeStart!)) {
            // Auto swap start date to current end
            final temp = _rangeStart;
            _rangeStart = _rangeEnd;
            _rangeEnd = temp;
            _activeSelector =
                'start'; // Optionally switch active to start after swap
          } else if (_rangeStart == null) {
            _activeSelector = 'start'; // Auto switch to empty bound
          }
        }
      });
    }
  }

  Future<void> _handleDateToggleTap(String selector) async {
    if (_activeSelector == selector) {
      final initialDate = selector == 'start'
          ? (_rangeStart ?? DateTime.now())
          : (_rangeEnd ?? DateTime.now());

      final newDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDatePickerMode: DatePickerMode.year,
      );

      if (newDate != null) {
        _onDaySelected(newDate, newDate);
      }
    } else {
      setState(() => _activeSelector = selector);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    // We are disabling native range selected by intercepting through _onDaySelected
    // but we can leave this stub here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isRangeSelection) ...[
            Container(
              decoration: BoxDecoration(
                color: AppConstants.bgElevated,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleDateToggleTap('start'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeSelector == 'start'
                              ? AppConstants.accentPrimary.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMD,
                          ),
                          border: Border.all(
                            color: _activeSelector == 'start'
                                ? AppConstants.accentPrimary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Start Date',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppConstants.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _rangeStart != null
                                  ? '${_rangeStart!.month}/${_rangeStart!.day}/${_rangeStart!.year}'
                                  : '--/--/----',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _activeSelector == 'start'
                                    ? AppConstants.textPrimary
                                    : AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleDateToggleTap('end'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeSelector == 'end'
                              ? AppConstants.accentPrimary.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMD,
                          ),
                          border: Border.all(
                            color: _activeSelector == 'end'
                                ? AppConstants.accentPrimary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'End Date',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppConstants.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _rangeEnd != null
                                  ? '${_rangeEnd!.month}/${_rangeEnd!.day}/${_rangeEnd!.year}'
                                  : '--/--/----',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _activeSelector == 'end'
                                    ? AppConstants.textPrimary
                                    : AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TableCalendar<MediaItem>(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: CalendarFormat.month,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppConstants.textPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppConstants.textPrimary,
              ),
            ),
            onHeaderTapped: (focusedDay) async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: focusedDay,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (newDate != null) {
                setState(() {
                  _focusedDay = newDate;
                });
              }
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppConstants.accentPrimary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppConstants.accentPrimary,
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: BoxDecoration(
                color: AppConstants.accentPrimary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: AppConstants.accentPrimary,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: AppConstants.accentPrimary.withValues(
                alpha: 0.2,
              ),
              markerSize: 6,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                bool hasPhoto = false;
                bool hasVideo = false;
                for (var e in events) {
                  if (e.mediaType == 'photo') {
                    hasPhoto = true;
                  } else if (e.mediaType == 'video')
                    hasVideo = true;
                }

                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPhoto)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppConstants.accentPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasVideo)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppConstants.accentSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            onDaySelected: _onDaySelected,
            // Since we intercept taps to handle arbitrary order picking, null out native range selected
            onRangeSelected: null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // If they want to clear filter:
                  if (widget.isRangeSelection && _rangeStart == null) {
                    Navigator.pop(context, null);
                  } else if (!widget.isRangeSelection && _selectedDay == null) {
                    Navigator.pop(context, null);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppConstants.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (widget.isRangeSelection) {
                    if (_rangeStart != null) {
                      Navigator.pop(
                        context,
                        DateTimeRange(
                          start: _rangeStart!,
                          end: _rangeEnd ?? _rangeStart!,
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  } else {
                    if (_selectedDay != null) {
                      Navigator.pop(context, _selectedDay);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
