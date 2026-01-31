import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_details_screen.dart'; // سننشئها في الخطوة التالية

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Specialist"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name or specialty...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب المستخدمين الذين دورهم "طبيب" فقط
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No doctors found."));

          final doctors = snapshot.data!.docs.where((doc) {
            final name = (doc['name'] as String).toLowerCase();
            final spec = (doc['specialization'] as String).toLowerCase();
            return name.contains(_searchQuery) || spec.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: (doc.data() as Map).containsKey('photoUrl') && doc['photoUrl'] != ""
                        ? NetworkImage(doc['photoUrl'])
                        : null,
                    child: !((doc.data() as Map).containsKey('photoUrl')) || doc['photoUrl'] == ""
                        ? const Icon(Icons.person) : null,
                  ),
                  title: Text("Dr. ${doc['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['specialization'] ?? "General Practitioner"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("\$${doc['fees'] ?? '0'}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("Fee", style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorData: doc)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
