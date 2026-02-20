import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic> _scheduleData = {};

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schedule')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayOptions(context, authProvider.user!.uid, selectedDay);
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dateStr = day.toIso8601String().split('T')[0];
                final isOpen = _scheduleData[dateStr]?['isOpen'] ?? false;
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.shade100 : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${day.day}')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDayOptions(BuildContext context, String doctorId, DateTime date) async {
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
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: $dateStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('Accepting Bookings'),
                  value: isOpen,
                  onChanged: (value) async {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(doctorId)
                        .collection('schedule')
                        .doc(dateStr)
                        .set({'isOpen': value, 'slots': slots}, SetOptions(merge: true));
                    setState(() => isOpen = value);
                  },
                ),
                if (isOpen) ...[
                  const Text('Time Slots:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...slots.map((slot) => ListTile(
                    title: Text('${slot['start']} - ${slot['end']}'),
                    trailing: slot['booked'] == true 
                        ? const Chip(label: Text('Booked'), backgroundColor: Colors.red))
                        : IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              slots.remove(slot);
                              await FirebaseFirestore.instance
                                  .collection('doctors')
                                  .doc(doctorId)
                                  .collection('schedule')
                                  .doc(dateStr)
                                  .update({'slots': slots});
                              setState(() {});
                            },
                          ),
                  )),
                  ElevatedButton.icon(
                    onPressed: () => _addTimeSlot(context, doctorId, dateStr, slots),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Slot'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

  void _addTimeSlot(BuildContext context, String doctorId, String dateStr, List<dynamic> currentSlots) {
    final startController = TextEditingController();
    final endController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: 'Start Time (e.g., 10:00)'),
            ),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: 'End Time (e.g., 10:30)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSlot = {
                'start': startController.text,
                'end': endController.text,
                'booked': false,
              };
              currentSlots.add(newSlot);
              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(doctorId)
                  .collection('schedule')
                  .doc(dateStr)
                  .update({'slots': currentSlots});
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
