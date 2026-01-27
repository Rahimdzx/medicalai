import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.language)),
      body: ListView(
        children: [
          _buildLanguageTile(
            context,
            languageProvider,
            'English',
            'en',
            '🇺🇸',
          ),
          _buildLanguageTile(
            context,
            languageProvider,
            'العربية',
            'ar',
            '🇸🇦',
          ),
          _buildLanguageTile(
            context,
            languageProvider,
            'Русский',
            'ru',
            '🇷🇺',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    LanguageProvider provider,
    String title,
    String code,
    String flag,
  ) {
    final isSelected = provider.locale.languageCode == code;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () async {
        await provider.setLocale(Locale(code));
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.languageChanged)),
          );
        }
      },
    );
  }
}
