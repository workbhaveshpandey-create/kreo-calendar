import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/event_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

/// Event Editor Bottom Sheet
/// Premium dark form for creating and editing events
class EventEditorSheet extends StatefulWidget {
  final EventModel? event;

  const EventEditorSheet({super.key, this.event});

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _uuid = const Uuid();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  Color _selectedColor = AppColors.eventColors[0];
  RecurrenceType _recurrence = RecurrenceType.none;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _locationController.text = widget.event!.location ?? '';
      _startDate = widget.event!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _endDate = widget.event!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.event!.endTime);
      _isAllDay = widget.event!.isAllDay;
      _selectedColor = widget.event!.color;
      _recurrence = widget.event!.recurrence;
    } else {
      // Get selected date from calendar state
      final calendarState = context.read<CalendarBloc>().state;
      if (calendarState is CalendarLoaded) {
        _startDate = calendarState.selectedDate;
      } else {
        _startDate = DateTime.now();
      }
      _startTime = TimeOfDay.now();
      _endDate = _startDate;
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 2.0,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    isEditing ? 'EDIT EVENT' : 'NEW EVENT',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 14,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveEvent,
                    child: Text(
                      'SAVE',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Title Input - Large & Clean
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter title',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.24,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: textColor,
                      ),

                      const SizedBox(height: 40),

                      // Time Section
                      _buildMinimalTimeSection(),

                      const SizedBox(height: 40),

                      // All Day Toggle (Minimal)
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'All-day',
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: _isAllDay,
                            onChanged: (val) => setState(() => _isAllDay = val),
                            activeColor: theme.colorScheme.onSurface,
                            activeTrackColor: theme.colorScheme.onSurface
                                .withOpacity(0.24),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: theme.colorScheme.surface,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Location Input
                      _buildMinimalTextField(
                        controller: _locationController,
                        icon: Icons.location_on_outlined,
                        hint: 'Add location',
                      ),

                      const SizedBox(height: 24),

                      // Description Input
                      _buildMinimalTextField(
                        controller: _descriptionController,
                        icon: Icons.notes_outlined,
                        hint: 'Add description',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 40),

                      // Color Selection
                      _buildMinimalColorPicker(),

                      const SizedBox(height: 40),

                      // Recurrence
                      _buildMinimalRecurrence(),

                      if (isEditing) ...[
                        const SizedBox(height: 60),
                        Center(
                          child: TextButton(
                            onPressed: _deleteEvent,
                            child: Text(
                              'DELETE EVENT',
                              style: GoogleFonts.poppins(
                                color: AppColors.minimalError,
                                letterSpacing: 2.0,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalTimeSection() {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Column(
      children: [
        _buildMinimalDateRow(
          label: 'FROM',
          date: dateFormat.format(_startDate).toUpperCase(),
          time: _isAllDay
              ? ''
              : timeFormat.format(
                  DateTime(2024, 1, 1, _startTime.hour, _startTime.minute),
                ),
          onTap: () => _selectDate(isStart: true),
          onTimeTap: _isAllDay ? null : () => _selectTime(isStart: true),
        ),
        const SizedBox(height: 24),
        _buildMinimalDateRow(
          label: 'TO',
          date: dateFormat.format(_endDate).toUpperCase(),
          time: _isAllDay
              ? ''
              : timeFormat.format(
                  DateTime(2024, 1, 1, _endTime.hour, _endTime.minute),
                ),
          onTap: () => _selectDate(isStart: false),
          onTimeTap: _isAllDay ? null : () => _selectTime(isStart: false),
        ),
      ],
    );
  }

  Widget _buildMinimalDateRow({
    required String label,
    required String date,
    required String time,
    required VoidCallback onTap,
    VoidCallback? onTimeTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              date,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (time.isNotEmpty)
          GestureDetector(
            onTap: onTimeTap,
            child: Text(
              time,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.24),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            cursorColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalColorPicker() {
    return Row(
      children: [
        Icon(
          Icons.palette_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppColors.eventColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = AppColors.eventColors[index];
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 2,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalRecurrence() {
    return Row(
      children: [
        Icon(
          Icons.cached_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RecurrenceType>(
              value: _recurrence,
              dropdownColor: Theme.of(context).cardColor,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              isExpanded: true,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              onChanged: (val) {
                if (val != null) setState(() => _recurrence = val);
              },
              items: RecurrenceType.values.map((type) {
                String label;
                switch (type) {
                  case RecurrenceType.none:
                    label = 'Does not repeat';
                    break;
                  case RecurrenceType.daily:
                    label = 'Every day';
                    break;
                  case RecurrenceType.weekly:
                    label = 'Every week';
                    break;
                  case RecurrenceType.monthly:
                    label = 'Every month';
                    break;
                  case RecurrenceType.yearly:
                    label = 'Every year';
                    break;
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showMinimalToast(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Invert colors for high contrast toast
    final bgColor = isError
        ? AppColors.minimalError
        : (isDark ? Colors.white : Colors.black);
    final tColor = isDark || isError ? Colors.black : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(
          bottom: 400,
          left: 24,
          right: 24,
        ), // Positioned higher
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: tColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.labelLarge(
                    color: tColor,
                  ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMinimalToast('PLEASE ENTER A TITLE', isError: true);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final calendarState = context.read<CalendarBloc>().state;
    if (calendarState is! CalendarLoaded) return;

    final defaultCalendar = calendarState.defaultCalendar;
    if (defaultCalendar == null) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 0 : _startTime.hour,
      _isAllDay ? 0 : _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _isAllDay ? 23 : _endTime.hour,
      _isAllDay ? 59 : _endTime.minute,
    );

    final event = EventModel(
      id: widget.event?.id ?? _uuid.v4(),
      calendarId: widget.event?.calendarId ?? defaultCalendar.id,
      userId: authState.user.uid,
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      color: _selectedColor,
      recurrence: _recurrence,
      googleEventId: widget.event?.googleEventId,
      createdAt: widget.event?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      context.read<CalendarBloc>().add(CalendarEventUpdated(event));
    } else {
      context.read<CalendarBloc>().add(CalendarEventCreated(event));
    }

    Navigator.pop(context);
  }

  void _deleteEvent() {
    if (widget.event != null) {
      context.read<CalendarBloc>().add(CalendarEventDeleted(widget.event!.id));
      Navigator.pop(context);
    }
  }
}
