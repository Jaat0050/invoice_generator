import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AppSettingsState {
  final String defaultTerms;
  final String defaultNotes;
  final int defaultDueDays;
  final bool autoRoundOff;
  final bool useIndianNumbering;

  const AppSettingsState({
    this.defaultTerms = '1. Payment is due within 15 days of invoice date.\n2. Interest @ 18% p.a. will be charged on delayed payments.\n3. Goods once sold will not be taken back.',
    this.defaultNotes = 'Thank you for your business! Please contact us for any billing inquiries.',
    this.defaultDueDays = 15,
    this.autoRoundOff = true,
    this.useIndianNumbering = true,
  });

  AppSettingsState copyWith({
    String? defaultTerms,
    String? defaultNotes,
    int? defaultDueDays,
    bool? autoRoundOff,
    bool? useIndianNumbering,
  }) {
    return AppSettingsState(
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      defaultDueDays: defaultDueDays ?? this.defaultDueDays,
      autoRoundOff: autoRoundOff ?? this.autoRoundOff,
      useIndianNumbering: useIndianNumbering ?? this.useIndianNumbering,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() => const AppSettingsState();

  void updateSettings(AppSettingsState updated) => state = updated;
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(AppSettingsNotifier.new);

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  late TextEditingController _termsController;
  late TextEditingController _notesController;
  late int _dueDays;
  late bool _autoRoundOff;
  late bool _useIndianNumbering;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _termsController = TextEditingController(text: settings.defaultTerms);
    _notesController = TextEditingController(text: settings.defaultNotes);
    _dueDays = settings.defaultDueDays;
    _autoRoundOff = settings.autoRoundOff;
    _useIndianNumbering = settings.useIndianNumbering;
  }

  @override
  void dispose() {
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ref.read(appSettingsProvider.notifier).updateSettings(
          AppSettingsState(
            defaultTerms: _termsController.text.trim(),
            defaultNotes: _notesController.text.trim(),
            defaultDueDays: _dueDays,
            autoRoundOff: _autoRoundOff,
            useIndianNumbering: _useIndianNumbering,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application preferences saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Preferences & Defaults'),
      ),
      body: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          // Invoice Defaults
          _buildSectionHeader('Default Payment Terms'),
          DropdownButtonFormField<int>(
            value: _dueDays,
            decoration: const InputDecoration(labelText: 'Default Payment Due Window'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Due on Receipt (Immediate)')),
              DropdownMenuItem(value: 7, child: Text('Net 7 Days')),
              DropdownMenuItem(value: 15, child: Text('Net 15 Days (Recommended)')),
              DropdownMenuItem(value: 30, child: Text('Net 30 Days')),
              DropdownMenuItem(value: 45, child: Text('Net 45 Days')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _dueDays = val);
            },
          ),
          const SizedBox(height: AppDimensions.lg),

          // Default Terms Template
          _buildSectionHeader('Default Terms & Conditions'),
          AppTextField(
            hint: 'Enter your standard invoice terms...',
            controller: _termsController,
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Default Notes Template
          _buildSectionHeader('Default Invoice Notes / Message'),
          AppTextField(
            hint: 'Enter default thank you notes...',
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Financial Preferences
          _buildSectionHeader('Calculation & Numbering Formats'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Auto Round-Off Total', style: AppTypography.labelLarge),
                  subtitle: Text('Round grand total to nearest ₹1.00', style: AppTypography.bodySmall),
                  value: _autoRoundOff,
                  onChanged: (v) => setState(() => _autoRoundOff = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Indian Numbering System', style: AppTypography.labelLarge),
                  subtitle: Text('Format figures as Lakhs (L) and Crores (Cr)', style: AppTypography.bodySmall),
                  value: _useIndianNumbering,
                  onChanged: (v) => setState(() => _useIndianNumbering = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),

          // Save Button
          AppButton(
            label: 'Save Preferences',
            icon: Icons.save_rounded,
            onPressed: _saveSettings,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
