import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class RussiaProgramsScreen extends StatelessWidget {
  const RussiaProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.medicalTourism)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildProgramCard(
            l10n.checkUp,
            "Full medical diagnostic in Moscow / Полная диагностика في موسكو",
            Icons.health_and_safety,
            Colors.blue,
          ),
          _buildProgramCard(
            "Plastic Surgery / Пластическая хирургия",
            "Advanced aesthetic procedures / Современные методы эстетики",
            Icons.face,
            Colors.purple,
          ),
          _buildProgramCard(
            l10n.imagingReview,
            "CT/MRI expert review / Пересмотр снимков КТ/МРТ",
            Icons.biotech,
            Colors.red,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              l10n.shareFeatureComingSoon,
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(String title, String desc, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Icon(icon, size: 40, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: () {},
      ),
    );
  }
}
