import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class MedicalTourismScreen extends StatelessWidget {
  const MedicalTourismScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicalTourism),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flight_takeoff, size: 48, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.medicalTourism,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.medicalTourismDesc,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Coming Soon Notice
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Coming Soon! We are partnering with top Russian medical centers.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Featured Programs
            Text(
              'Featured Programs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildProgramCard(
              icon: Icons.favorite,
              title: 'Cardiac Surgery',
              description: 'World-class cardiac treatment at leading Russian hospitals',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildProgramCard(
              icon: Icons.psychology,
              title: 'Neurology & Neurosurgery',
              description: 'Advanced neurological care and brain surgery',
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildProgramCard(
              icon: Icons.child_care,
              title: 'Pediatric Care',
              description: 'Specialized treatment for children of all ages',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildProgramCard(
              icon: Icons.local_hospital,
              title: 'Oncology Treatment',
              description: 'Comprehensive cancer care and therapy',
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Contact Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interested? Contact Us',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our medical tourism coordinators will help you plan your treatment journey in Russia.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement contact form
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact form coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.email),
                        label: const Text('Request Information'),
                      ),
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

  Widget _buildProgramCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to program details
        },
      ),
    );
  }
}
