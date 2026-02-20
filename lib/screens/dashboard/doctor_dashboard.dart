import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/constants/colors.dart';
import '../common/qr_share_scan_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic> _scheduleData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    final schedule = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(auth.user!.uid)
        .collection('schedule')
        .get();

    setState(() {
      for (var doc in schedule.docs) {
        _scheduleData[doc.id] = doc.data();
      }
    });
  }

  Future<void> _toggleDateAvailability(DateTime date) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dateStr = date.toIso8601String().split('T')[0];
    final isCurrentlyOpen = _scheduleData[dateStr]?['isOpen'] ?? false;

    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(auth.user!.uid)
        .collection('schedule')
        .doc(dateStr)
        .set({
      'isOpen': !isCurrentlyOpen,
      'slots': [],
    }, SetOptions(merge: true));

    setState(() {
      _scheduleData[dateStr] = {
        ...(_scheduleData[dateStr] ?? {}),
        'isOpen': !isCurrentlyOpen,
      };
    });
  }

  void _showAddTimeSlotDialog(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTimeSlot),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startTimeController,
              decoration: InputDecoration(labelText: l10n.startTime),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: endTimeController,
              decoration: InputDecoration(labelText: l10n.endTime),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final dateStr = date.toIso8601String().split('T')[0];
              final newSlot = {
                'start': startTimeController.text,
                'end': endTimeController.text,
                'booked': false,
                'patientId': null,
              };

              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(auth.user!.uid)
                  .collection('schedule')
                  .doc(dateStr)
                  .update({
                'slots': FieldValue.arrayUnion([newSlot]),
              });

              Navigator.pop(context);
              _loadSchedule();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                            ? NetworkImage(auth.photoUrl!)
                            : null,
                        child: (auth.photoUrl == null || auth.photoUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.welcomeBack, 
                              style: const TextStyle(color: Colors.white70, fontSize: 12)
                            ),
                            Text(
                              auth.userName ?? "Dr. Unknown", 
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 20, 
                                fontWeight: FontWeight.bold
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => auth.signOut(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: auth.user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int total = snapshot.data?.docs.length ?? 0;
                        int today = 0;
                        if (snapshot.hasData) {
                          final now = DateTime.now();
                          today = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final created = data['createdAt']?.toDate();
                            return created != null &&
                                created.day == now.day &&
                                created.month == now.month &&
                                created.year == now.year;
                          }).length;
                        }

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(label: l10n.totalPatients, value: total.toString()),
                              _StatItem(label: l10n.todayAppointments, value: today.toString()),
                              _StatItem(label: l10n.rating, value: "4.9"),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // QR Actions
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code, 
                            label: l10n.myQrCode, 
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => QRDisplayScreen(
                                    data: auth.user?.uid ?? "error",
                                    title: auth.userName ?? "Doctor",
                                    description: "Scan to book appointment"
                                  )
                                )
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.calendar_today, 
                            label: l10n.mySchedule, 
                            color: Colors.green,
                            onTap: () => _showScheduleCalendar(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Recent Appointments
                    Text(
                      l10n.recentAppointments,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: auth.user?.uid)
                          .orderBy('createdAt', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(l10n.noAppointments),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppColors.primary),
                                ),
                                title: Text(data['patientName'] ?? 'Patient'),
                                subtitle: Text(
                                  '${data['format']} • ${data['timeSlot']}',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: data['status'] == 'confirmed' 
                                        ? Colors.green.shade100 
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data['status'] ?? 'pending',
                                    style: TextStyle(
                                      color: data['status'] == 'confirmed' 
                                          ? Colors.green.shade800 
                                          : Colors.orange.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  // Open chat
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        appointmentId: doc.id,
                                        receiverName: data['patientName'] ?? 'Patient',
                                        chatId: data['chatId'] ?? doc.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleCalendar() {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                l10n.scheduleManagement,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                  _showDayOptions(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateStr = day.toIso8601String().split('T')[0];
                    final isOpen = _scheduleData[dateStr]?['isOpen'] ?? false;
                    final hasSlots = (_scheduleData[dateStr]?['slots'] as List?)?.isNotEmpty ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green.shade100 : null,
                        borderRadius: BorderRadius.circular(8),
                        border: hasSlots ? Border.all(color: Colors.green) : null,
                      ),
                      child: Center(child: Text('${day.day}')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayOptions(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = date.toIso8601String().split('T')[0];
    final isOpen = _scheduleData[dateStr]?['isOpen'] ?? false;
    final slots = (_scheduleData[dateStr]?['slots'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.date}: $dateStr',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.acceptingBookings),
              value: isOpen,
              onChanged: (value) {
                Navigator.pop(context);
                _toggleDateAvailability(date);
              },
            ),
            if (isOpen) ...[
              const Divider(),
              Text(l10n.timeSlots, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (slots.isEmpty)
                Text(l10n.noTimeSlots),
              ...slots.map((slot) => ListTile(
                dense: true,
                title: Text('${slot['start']} - ${slot['end']}'),
                trailing: slot['booked'] == true
                    ? Chip(label: Text(l10n.booked), backgroundColor: Colors.red.shade100)
                    : null,
              )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddTimeSlotDialog(date);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addTimeSlot),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value, 
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: AppColors.primary
          )
        ),
        Text(
          label, 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              label, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}
