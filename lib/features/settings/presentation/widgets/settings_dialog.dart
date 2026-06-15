import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../../../formatter/presentation/providers/json_formatter_provider.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sectionTitleStyle = GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
    );

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 12),
          Text(
            'Settings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // APPEARANCE SECTION
              Text('Appearance', style: sectionTitleStyle),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Theme Mode'),
                subtitle: const Text('Select application theme preference'),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  onChanged: (ThemeMode? val) {
                    if (val != null) notifier.setThemeMode(val);
                  },
                  items: const [
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System Mode')),
                  ],
                ),
              ),
              const Divider(),

              // EDITOR SETTINGS SECTION
              Text('Editor Config', style: sectionTitleStyle),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Font Family'),
                subtitle: const Text('Customize editor typeface'),
                trailing: DropdownButton<String>(
                  value: settings.fontFamily,
                  onChanged: (String? val) {
                    if (val != null) notifier.setFontFamily(val);
                  },
                  items: const [
                    DropdownMenuItem(value: 'JetBrains Mono', child: Text('JetBrains Mono')),
                    DropdownMenuItem(value: 'Fira Code', child: Text('Fira Code')),
                    DropdownMenuItem(value: 'Roboto Mono', child: Text('Roboto Mono')),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Font Size'),
                subtitle: Text('${settings.fontSize.toInt()} px'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    min: 11,
                    max: 20,
                    divisions: 9,
                    value: settings.fontSize,
                    label: '${settings.fontSize.toInt()}',
                    onChanged: (double val) => notifier.setFontSize(val),
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Word Wrap'),
                subtitle: const Text('Enable horizontal line wrapping'),
                value: settings.wordWrap,
                onChanged: (bool val) => notifier.setWordWrap(val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Line Numbers'),
                subtitle: const Text('Display line indexing sidebar'),
                value: settings.showLineNumbers,
                onChanged: (bool val) => notifier.setShowLineNumbers(val),
              ),
              const Divider(),

              // FORMATTER SETTINGS SECTION
              Text('Formatter Settings', style: sectionTitleStyle),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Indentation Spacing'),
                subtitle: const Text('Set tab-width for pretty printing'),
                trailing: ToggleButtons(
                  isSelected: [
                    settings.indentSize == 2,
                    settings.indentSize == 4,
                    // If not 2 and not 4, it's tab
                    settings.indentSize != 2 && settings.indentSize != 4,
                  ],
                  onPressed: (int index) {
                    if (index == 0) notifier.setIndentSize(2);
                    if (index == 1) notifier.setIndentSize(4);
                    if (index == 2) notifier.setIndentSize(1); // 1 = Tab code
                    // Trigger re-format
                    ref.read(jsonFormatterProvider.notifier).format();
                  },
                  borderRadius: BorderRadius.circular(6),
                  constraints: const BoxConstraints(minWidth: 50, minHeight: 32),
                  children: const [
                    Text('2 S'),
                    Text('4 S'),
                    Text('Tab'),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Format'),
                subtitle: const Text('Automatically format valid typed JSON'),
                value: settings.autoFormat,
                onChanged: (bool val) => notifier.setAutoFormat(val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
