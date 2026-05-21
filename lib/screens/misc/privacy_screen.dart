import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareUsage = true;
  bool _personalizedRecs = true;
  bool _locationData = false;
  bool _crashReports = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Privacy & Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(
            'Control how your data is used and stored.',
            style: TextStyle(
                color: AppColors.textSec(context), fontSize: 14),
          ),
          const SizedBox(height: 24),
          // ---- Data Sharing ----
          _section(context, 'Data Sharing', [
            _switchRow(
              context,
              'Share Anonymous Usage Data',
              'Help us improve ShelfLife with anonymous analytics.',
              Icons.bar_chart,
              _shareUsage,
              (v) => setState(() => _shareUsage = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Personalized Recommendations',
              'Use your pantry history to suggest better recipes.',
              Icons.recommend,
              _personalizedRecs,
              (v) => setState(() => _personalizedRecs = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Location Data',
              'Find seasonal recipes for your region.',
              Icons.location_on_outlined,
              _locationData,
              (v) => setState(() => _locationData = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Crash & Error Reports',
              'Automatically send crash logs to help us fix bugs.',
              Icons.bug_report_outlined,
              _crashReports,
              (v) => setState(() => _crashReports = v),
            ),
          ]),
          const SizedBox(height: 16),
          // ---- Data Management ----
          _section(context, 'Your Data', [
            _navRow(context, Icons.cloud_download_outlined,
                'Download My Data', 'Get a copy of your pantry data in CSV.', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Your data export will be ready shortly.')),
              );
            }),
            _divider(context),
            _navRow(context, Icons.history, 'View Login Activity',
                'See recent sign-ins to your account.', () {}),
            _divider(context),
            _navRow(context, Icons.devices_other,
                'Connected Devices', 'Manage where you\'re signed in.', () {}),
          ]),
          const SizedBox(height: 16),
          // ---- Documents ----
          _section(context, 'Legal', [
            _navRow(context, Icons.description_outlined, 'Privacy Policy', null,
                () {}),
            _divider(context),
            _navRow(context, Icons.gavel_outlined, 'Terms of Service', null,
                () {}),
            _divider(context),
            _navRow(context, Icons.cookie_outlined, 'Cookie Preferences', null,
                () {}),
          ]),
          const SizedBox(height: 20),
          // ---- Destructive actions ----
          OutlinedButton.icon(
            onPressed: () => _showClearDialog(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              foregroundColor: AppColors.danger,
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear All Pantry Data'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'For more info, visit shelflife.app/privacy',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMut(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helpers -------------------------------------------------------------

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, IconData icon, String title,
      String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPri(context),
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSec(context)),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: AppColors.divider(context));

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Pantry Data?'),
        content: const Text(
          'This will permanently remove all your pantry items, recipes, and shopping list. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All pantry data cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
