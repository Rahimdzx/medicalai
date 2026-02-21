import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final String? doctorId;

  const ScheduleManagementScreen({super.key, this.doctorId});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic> _scheduleData = {};
  int _slotDuration = 30; // Default 30 minutes

  String get _doctorId => widget.doctorId ?? Provider.of<AuthProvider>(context, listen: false).user!.uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schedule),
        actions: [
          // Duration setting
          PopupMenuButton<int>(
            icon: const Icon(Icons.settings),
            tooltip: 'Slot Duration',
            onSelected: (duration) => setState(() => _slotDuration = duration),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 15, child: Text('15 minutes')),
              const PopupMenuItem(value: 30, child: Text('30 minutes')),
              const PopupMenuItem(value: 45, child: Text('45 minutes')),
              const PopupMenuItem(value: 60, child: Text('60 minutes')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .doc(_doctorId)
            .snapshots(),
        builder: (context, doctorSnapshot) {
          String doctorName = 'Doctor';
          if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
            final data = doctorSnapshot.data!.data() as Map<String, dynamic>;
            doctorName = data['name'] ?? 'Doctor';
          }

          return Column(
            children: [
              // Doctor info header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Managing schedule for: $doctorName',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              
              // Calendar
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 180)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showDayOptions(context, _doctorId, selectedDay);
                },
                onFormatChanged: (format) =>
                    setState(() => _calendarFormat = format),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateStr = day.toIso8601String().split('T')[0];
                    final schedule = _scheduleData[dateStr];
                    final isOpen = schedule?['isOpen'] ?? false;
                    final hasSlots = (schedule?['slots'] as List?)?.isNotEmpty ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isOpen 
                            ? (hasSlots ? Colors.green.shade100 : Colors.orange.shade100)
                            : null,
                        shape: BoxShape.circle,
                        border: isSameDay(day, DateTime.now())
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isOpen ? Colors.black : Colors.grey,
                            fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const Divider(),
              
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green.shade100, 'Open with slots'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.orange.shade100, 'Open, no slots'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.grey.shade200, 'Closed'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBulkScheduleDialog(context),
                        icon: const Icon(Icons.date_range),
                        label: const Text('Bulk Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showDayOptions(
      BuildContext context, String doctorId, DateTime date) async {
    final l10n = AppLocalizations.of(context);
    final dateStr = date.toIso8601String().split('T')[0];
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .doc(dateStr)
        .get();

    final currentData = doc.data();
    bool isOpen = currentData?['isOpen'] ?? false;
    List<dynamic> slots = currentData?['slots'] ?? [];

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${l10n.selectDate}: $dateStr',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.acceptingBookings),
                  subtitle: Text(isOpen ? 'Patients can book' : 'Booking disabled'),
                  value: isOpen,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(doctorId)
                        .collection('schedule')
                        .doc(dateStr)
                        .set(
                          {'isOpen': value, 'slots': slots},
                          SetOptions(merge: true),
                        );
                    setState(() => isOpen = value);
                  },
                ),
                const Divider(),
                if (isOpen) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.appointments,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _addTimeSlot(context, doctorId, dateStr, slots, setState),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addTimeSlot),
                      ),
                    ],
                  ),
                  if (slots.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No time slots added yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return ListTile(
                            leading: Icon(
                              slot['booked'] == true 
                                  ? Icons.lock 
                                  : Icons.access_time,
                              color: slot['booked'] == true ? Colors.red : Colors.green,
                            ),
                            title: Text('${slot['start']} - ${slot['end']}'),
                            trailing: slot['booked'] == true
                                ? Chip(
                                    label: Text(l10n.booked),
                                    backgroundColor: Colors.red.shade100,
                                    labelStyle: const TextStyle(color: Colors.red),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      slots.removeAt(index);
                                      await FirebaseFirestore.instance
                                          .collection('doctors')
                                          .doc(doctorId)
                                          .collection('schedule')
                                          .doc(dateStr)
                                          .update({'slots': slots});
                                      setState(() {});
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Enable "Accepting Bookings" to add time slots',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

  void _addTimeSlot(
    BuildContext context,
    String doctorId,
    String dateStr,
    List<dynamic> currentSlots,
    StateSetter setState,
  ) {
    final l10n = AppLocalizations.of(context);
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTimeSlot),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(startTime?.format(context) ?? 'Not selected'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                );
                if (time != null) {
                  startTime = time;
                  // Auto-calculate end time based on duration
                  final endMinutes = time.hour * 60 + time.minute + _slotDuration;
                  endTime = TimeOfDay(
                    hour: endMinutes ~/ 60,
                    minute: endMinutes % 60,
                  );
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('End Time'),
              subtitle: Text(endTime?.format(context) ?? 'Not selected'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime ?? const TimeOfDay(hour: 9, minute: 30),
                );
                if (time != null) {
                  endTime = time;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $_slotDuration minutes',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: startTime != null && endTime != null
                ? () async {
                    final newSlot = {
                      'start': startTime!.format(context),
                      'end': endTime!.format(context),
                      'booked': false,
                      'duration': _slotDuration,
                    };
                    currentSlots.add(newSlot);
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(doctorId)
                        .collection('schedule')
                        .doc(dateStr)
                        .update({'slots': currentSlots});
                    Navigator.pop(context);
                    setState(() {});
                  }
                : null,
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showBulkScheduleDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    DateTimeRange? dateRange;
    TimeOfDay? startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? endTime = const TimeOfDay(hour: 17, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri by default

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bulk Schedule Creator'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Date Range'),
                  subtitle: Text(
                    dateRange != null
                        ? '${dateRange!.start.toIso8601String().split('T')[0]} to ${dateRange!.end.toIso8601String().split('T')[0]}'
                        : 'Not selected',
                  ),
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (range != null) {
                      setState(() => dateRange = range);
                    }
                  },
                ),
                
                // Working Hours
                const SizedBox(height: 16),
                const Text('Working Hours:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('From'),
                        subtitle: Text(startTime?.format(context) ?? '9:00 AM'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: startTime!,
                          );
                          if (time != null) setState(() => startTime = time);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('To'),
                        subtitle: Text(endTime?.format(context) ?? '5:00 PM'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: endTime!,
                          );
                          if (time != null) setState(() => endTime = time);
                        },
                      ),
                    ),
                  ],
                ),
                
                // Weekday Selection
                const SizedBox(height: 16),
                const Text('Working Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    _DayChip(
                      label: 'Mon',
                      selected: selectedDays.contains(1),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(1) : selectedDays.remove(1);
                      }),
                    ),
                    _DayChip(
                      label: 'Tue',
                      selected: selectedDays.contains(2),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(2) : selectedDays.remove(2);
                      }),
                    ),
                    _DayChip(
                      label: 'Wed',
                      selected: selectedDays.contains(3),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(3) : selectedDays.remove(3);
                      }),
                    ),
                    _DayChip(
                      label: 'Thu',
                      selected: selectedDays.contains(4),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(4) : selectedDays.remove(4);
                      }),
                    ),
                    _DayChip(
                      label: 'Fri',
                      selected: selectedDays.contains(5),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(5) : selectedDays.remove(5);
                      }),
                    ),
                    _DayChip(
                      label: 'Sat',
                      selected: selectedDays.contains(6),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(6) : selectedDays.remove(6);
                      }),
                    ),
                    _DayChip(
                      label: 'Sun',
                      selected: selectedDays.contains(7),
                      onSelected: (selected) => setState(() {
                        selected ? selectedDays.add(7) : selectedDays.remove(7);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: dateRange != null && selectedDays.isNotEmpty
                  ? () async {
                      await _createBulkSchedule(
                        dateRange!,
                        startTime!,
                        endTime!,
                        selectedDays,
                      );
                      if (mounted) Navigator.pop(context);
                    }
                  : null,
              child: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBulkSchedule(
    DateTimeRange range,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<int> weekdays,
  ) async {
    final doctorId = _doctorId;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Generate time slots
    final slots = <Map<String, dynamic>>[];
    var currentMinutes = startMinutes;
    while (currentMinutes + _slotDuration <= endMinutes) {
      final startHour = currentMinutes ~/ 60;
      final startMin = currentMinutes % 60;
      final endHour = (currentMinutes + _slotDuration) ~/ 60;
      final endMin = (currentMinutes + _slotDuration) % 60;

      slots.add({
        'start': '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}',
        'end': '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}',
        'booked': false,
        'duration': _slotDuration,
      });

      currentMinutes += _slotDuration;
    }

    // Apply to each day in range
    var currentDate = range.start;
    while (!currentDate.isAfter(range.end)) {
      if (weekdays.contains(currentDate.weekday)) {
        final dateStr = currentDate.toIso8601String().split('T')[0];
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('schedule')
            .doc(dateStr)
            .set({
          'isOpen': true,
          'slots': slots,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk schedule created successfully')),
      );
    }
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.blue.shade100,
    );
  }
}
