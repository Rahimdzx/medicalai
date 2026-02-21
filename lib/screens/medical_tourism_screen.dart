import 'package:flutter/material.dart';

class MedicalTourismScreen extends StatelessWidget {
  const MedicalTourismScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Tourism'),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.purple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flight_takeoff, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Medical Tourism',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'World-class healthcare at affordable destinations',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Services
            const Text(
              'Our Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildServiceCard(
              icon: Icons.local_hospital,
              title: 'Treatment Packages',
              description: 'Comprehensive medical treatment packages including surgery, recovery, and follow-up care.',
              color: Colors.blue,
            ),
            _buildServiceCard(
              icon: Icons.hotel,
              title: 'Travel & Accommodation',
              description: 'We arrange flights, visa assistance, and comfortable accommodation near medical facilities.',
              color: Colors.orange,
            ),
            _buildServiceCard(
              icon: Icons.translate,
              title: 'Translation Services',
              description: 'Professional medical interpreters to ensure clear communication with your healthcare team.',
              color: Colors.green,
            ),
            _buildServiceCard(
              icon: Icons.airport_shuttle,
              title: 'Local Transportation',
              description: 'Airport transfers and transportation to medical appointments included.',
              color: Colors.red,
            ),
            
            const SizedBox(height: 24),
            
            // Popular Destinations
            const Text(
              'Popular Destinations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildDestinationCard('Germany', '🇩🇪', 'Advanced surgery'),
                  _buildDestinationCard('Turkey', '🇹🇷', 'Hair transplant'),
                  _buildDestinationCard('Thailand', '🇹🇭', 'Dental care'),
                  _buildDestinationCard('India', '🇮🇳', 'Cardiac surgery'),
                  _buildDestinationCard('UAE', '🇦🇪', 'Cosmetic surgery'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showInquiryDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Request Consultation',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(String country, String flag, String specialty) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            country,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            specialty,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInquiryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'Medical tourism booking will be available soon. Please contact our support team for inquiries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
