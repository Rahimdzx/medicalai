import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/constants/colors.dart';

/// A widget for selecting and displaying the current language
class LanguageSelector extends StatelessWidget {
  /// Whether to show the full language name or just the flag
  final bool showName;

  /// Whether this is used in an app bar
  final bool isAppBarAction;

  /// Custom callback when language changes
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    super.key,
    this.showName = true,
    this.isAppBarAction = false,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (isAppBarAction) {
      return _buildAppBarButton(context, languageProvider);
    }

    return _buildDropdown(context, languageProvider);
  }

  Widget _buildAppBarButton(BuildContext context, LanguageProvider provider) {
    return PopupMenuButton<String>(
      icon: Text(
        provider.currentLanguageFlag,
        style: const TextStyle(fontSize: 24),
      ),
      tooltip: 'Change language',
      onSelected: (code) async {
        await provider.changeLanguage(code);
        onLanguageChanged?.call();
      },
      itemBuilder: (context) {
        return provider.availableLanguages.map((lang) {
          return PopupMenuItem<String>(
            value: lang.code,
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(lang.name),
                if (lang.isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildDropdown(BuildContext context, LanguageProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.languageCode,
          icon: const Icon(Icons.arrow_drop_down),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (String? code) async {
            if (code != null) {
              await provider.changeLanguage(code);
              onLanguageChanged?.call();
            }
          },
          items: provider.availableLanguages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang.code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 20)),
                  if (showName) ...[
                    const SizedBox(width: 8),
                    Text(lang.name),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// A full-screen language selection dialog
class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Language'),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: languageProvider.availableLanguages.map((lang) {
          return ListTile(
            leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
            title: Text(lang.name),
            subtitle: lang.isRTL ? const Text('Right-to-left') : null,
            trailing: lang.isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            selected: lang.isSelected,
            onTap: () async {
              await languageProvider.changeLanguage(lang.code);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}

/// A tile for use in settings screens
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(languageProvider.currentLanguageName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageProvider.currentLanguageFlag,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => LanguageSelectionDialog.show(context),
    );
  }
}

/// A bottom sheet for language selection
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LanguageBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.language, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Select Language',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Language options
          ...languageProvider.availableLanguages.map((lang) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lang.isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                ),
              ),
              title: Text(
                lang.name,
                style: TextStyle(
                  fontWeight: lang.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: lang.isRTL
                  ? Text(
                      'Right-to-left',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    )
                  : null,
              trailing: lang.isSelected
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : null,
              onTap: () async {
                await languageProvider.changeLanguage(lang.code);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
