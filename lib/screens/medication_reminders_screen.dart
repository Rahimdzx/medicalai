import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() => _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationReminders ?? 'Medication Reminders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: authProvider.user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noReminders ?? 'No reminders set',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a medication reminder',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index].data() as Map<String, dynamic>;
              final reminderId = reminders[index].id;

              return _ReminderCard(
                reminder: reminder,
                reminderId: reminderId,
                onDelete: () => _deleteReminder(reminderId),
                onToggle: (enabled) => _toggleReminder(reminderId, enabled),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addReminder ?? 'Add Reminder'),
      ),
    );
  }

  Future<void> _showAddReminderDialog() async {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    List<bool> selectedDays = List.filled(7, true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addReminder ?? 'Add Medication Reminder',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.medicationName ?? 'Medication Name',
                  prefixIcon: const Icon(Icons.medication),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: dosageController,
                decoration: InputDecoration(
                  labelText: l10n.dosage ?? 'Dosage (e.g., 1 tablet)',
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(l10n.reminderTime ?? 'Reminder Time'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                  child: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.repeatDays ?? 'Repeat on days:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => selectedDays[index] = !selectedDays[index]);
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: selectedDays[index]
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: selectedDays[index] ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) return;

                        await FirebaseFirestore.instance.collection('reminders').add({
                          'userId': authProvider.user?.uid,
                          'medicationName': nameController.text.trim(),
                          'dosage': dosageController.text.trim(),
                          'time': '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          'days': selectedDays,
                          'enabled': true,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.reminderAdded ?? 'Reminder added'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReminder(String reminderId) async {
    final l10n = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReminder ?? 'Delete Reminder'),
        content: Text(l10n.deleteReminderConfirm ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('reminders').doc(reminderId).delete();
    }
  }

  Future<void> _toggleReminder(String reminderId, bool enabled) async {
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .update({'enabled': enabled});
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final String reminderId;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.reminderId,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = reminder['enabled'] ?? true;
    final days = List<bool>.from(reminder['days'] ?? List.filled(7, true));
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled
                        ? theme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: enabled ? theme.primaryColor : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder['medicationName'] ?? 'Medication',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: enabled ? null : Colors.grey,
                        ),
                      ),
                      if (reminder['dosage']?.isNotEmpty ?? false)
                        Text(
                          reminder['dosage'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  reminder['time'] ?? '00:00',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: enabled ? theme.primaryColor : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(7, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: days[index]
                            ? (enabled ? theme.primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: days[index]
                              ? (enabled ? theme.primaryColor : Colors.grey)
                              : Colors.grey[400],
                          fontWeight: days[index] ? FontWeight.bold : null,
                        ),
                      ),
                    );
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
