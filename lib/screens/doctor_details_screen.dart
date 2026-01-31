import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot doctorData;
  const DoctorDetailsScreen({super.key, required this.doctorData});

  @override
  Widget build(BuildContext context) {
    final data = doctorData.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(data['name'])),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200, width: double.infinity,
              color: Colors.blue.shade50,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: data['photoUrl'] != "" ? NetworkImage(data['photoUrl']) : null,
                child: data['photoUrl'] == "" ? const Icon(Icons.person, size: 80) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. ${data['name']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(data['specialization'] ?? "Specialist", style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
                  const Divider(height: 40),
                  _buildInfoRow(Icons.monetization_on, "Consultation Fee", "\$${data['fees']}"),
                  _buildInfoRow(Icons.phone, "Contact", data['phone'] ?? "Not provided"),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        // هنا يتم ربط بوابة الدفع أو إرسال طلب حجز
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Redirecting to payment..."))
                        );
                      },
                      child: const Text("Book and Pay Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
