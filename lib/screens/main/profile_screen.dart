import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _avatar(),
          const SizedBox(height: 12),
          const Center(
            child: Text('Elena Rodriguez',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const Center(
            child: Text('elena.rod@example.com',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          _settingsCard(),
          const SizedBox(height: 14),
          _dietaryCard(),
          const SizedBox(height: 14),
          _allergiesCard(),
          const SizedBox(height: 14),
          _analyticsCard(),
          const SizedBox(height: 14),
          _navTile(Icons.manage_accounts, 'Edit Profile Details'),
          const SizedBox(height: 10),
          _navTile(Icons.shield_outlined, 'Privacy & Data'),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_outline, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Delete Account',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('ShelfLife Version 2.4.0 (2024)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.chipBg,
              child: ClipOval(
                child: Image.asset(
                  'assets/profile/avatar_default.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Settings',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined,
                  color: AppColors.textPrimary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Dark Mode', style: TextStyle(fontSize: 15)),
              ),
              Switch(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.textPrimary),
              const SizedBox(width: 12),
              const Expanded(
                child:
                    Text('Push Notifications', style: TextStyle(fontSize: 15)),
              ),
              Switch(
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dietaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('Dietary Focus',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.restaurant, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Vegetarian', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Organic', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Gluten-Free', const Color(0xFFFFF3E0), const Color(0xFFB45309)),
              _pill('+ Add Focus', AppColors.chipBg, AppColors.textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allergiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.danger, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Allergies & Sensitivities',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          _allergyRow('Peanuts & Tree Nuts'),
          const SizedBox(height: 8),
          _allergyRow('Shellfish'),
        ],
      ),
    );
  }

  Widget _allergyRow(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 15))),
          const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }

  Widget _analyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('Pantry Analytics',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.bar_chart, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waste Reduction',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const labels = ['Jan', 'Feb', 'Mar', 'Apr'];
                                  if (v.toInt() < 0 || v.toInt() >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    labels[v.toInt()],
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                                reservedSize: 20,
                              ),
                            ),
                          ),
                          minX: 0, maxX: 3,
                          minY: 0, maxY: 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 7),
                                FlSpot(1, 6),
                                FlSpot(2, 4),
                                FlSpot(3, 3),
                              ],
                              isCurved: true,
                              color: AppColors.primaryDark,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Distribution',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              startDegreeOffset: 270,
                              sections: [
                                PieChartSectionData(
                                  value: 60,
                                  color: AppColors.primaryDark,
                                  radius: 14,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 40,
                                  color: AppColors.primaryLight,
                                  radius: 14,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('42',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text('items',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot(color: AppColors.primaryDark, label: 'Produce'),
                        SizedBox(width: 10),
                        _LegendDot(color: AppColors.primaryLight, label: 'Dairy'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _navTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
