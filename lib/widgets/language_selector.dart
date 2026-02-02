import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

/// A reusable language selector widget that can be used as a dropdown,
/// dialog, or bottom sheet depending on the display mode.
class LanguageSelector extends StatelessWidget {
  final LanguageSelectorMode mode;
  final bool showFlags;
  final bool showCurrentLanguage;
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    super.key,
    this.mode = LanguageSelectorMode.dropdown,
    this.showFlags = true,
    this.showCurrentLanguage = true,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case LanguageSelectorMode.dropdown:
        return _buildDropdown(context);
      case LanguageSelectorMode.iconButton:
        return _buildIconButton(context);
      case LanguageSelectorMode.listTile:
        return _buildListTile(context);
    }
  }

  Widget _buildDropdown(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentCode = languageProvider.languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentCode,
          icon: const Icon(Icons.arrow_drop_down),
          isDense: true,
          items: LanguageProvider.supportedLanguages.map((code) {
            return DropdownMenuItem(
              value: code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showFlags) ...[
                    Text(
                      languageProvider.getLanguageFlag(code),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(languageProvider.getLanguageDisplayName(code)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newCode) async {
            if (newCode != null) {
              await languageProvider.changeLanguage(newCode);
              onLanguageChanged?.call();
            }
          },
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: AppLocalizations.of(context).language,
      onPressed: () => _showLanguageDialog(context),
    );
  }

  Widget _buildListTile(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);
    final currentCode = languageProvider.languageCode;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: showCurrentLanguage
          ? Text(languageProvider.getLanguageDisplayName(currentCode))
          : null,
      trailing: showFlags
          ? Text(
              languageProvider.getLanguageFlag(currentCode),
              style: const TextStyle(fontSize: 24),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _showLanguageBottomSheet(context),
    );
  }

  static void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LanguageProvider.supportedLanguages.map((code) {
              final isSelected = languageProvider.languageCode == code;
              return ListTile(
                leading: Text(
                  languageProvider.getLanguageFlag(code),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(languageProvider.getLanguageDisplayName(code)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                selected: isSelected,
                onTap: () async {
                  await languageProvider.changeLanguage(code);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).languageChanged),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  static void _showLanguageBottomSheet(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.selectLanguage,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ...LanguageProvider.supportedLanguages.map((code) {
                  final isSelected = languageProvider.languageCode == code;
                  return ListTile(
                    leading: Text(
                      languageProvider.getLanguageFlag(code),
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      languageProvider.getLanguageDisplayName(code),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green.shade600)
                        : null,
                    onTap: () async {
                      await languageProvider.changeLanguage(code);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).languageChanged),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a language selection dialog - can be called from anywhere
  static void showLanguageSelector(BuildContext context, {bool useBottomSheet = true}) {
    if (useBottomSheet) {
      _showLanguageBottomSheet(context);
    } else {
      _showLanguageDialog(context);
    }
  }
}

enum LanguageSelectorMode {
  dropdown,
  iconButton,
  listTile,
}

/// A compact language switcher button that cycles through languages
class LanguageSwitcherButton extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  final double iconSize;

  const LanguageSwitcherButton({
    super.key,
    this.showLabel = false,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentCode = languageProvider.languageCode;

    if (showLabel) {
      return TextButton.icon(
        onPressed: () => LanguageSelector.showLanguageSelector(context),
        icon: Text(
          languageProvider.getLanguageFlag(currentCode),
          style: TextStyle(fontSize: iconSize),
        ),
        label: Text(languageProvider.getLanguageDisplayName(currentCode)),
      );
    }

    return IconButton(
      onPressed: () => LanguageSelector.showLanguageSelector(context),
      icon: Text(
        languageProvider.getLanguageFlag(currentCode),
        style: TextStyle(fontSize: iconSize),
      ),
      tooltip: AppLocalizations.of(context).changeLanguage,
    );
  }
}
