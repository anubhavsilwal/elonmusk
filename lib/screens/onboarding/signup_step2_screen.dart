import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'signup_step3_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});
  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final Set<String> _selected = {'Vegan'};

  final _options = const [
    {'label': 'Vegan', 'icon': Icons.eco, 'color': AppColors.primaryLight, 'iconColor': AppColors.primaryDark},
    {'label': 'Keto', 'icon': Icons.flash_on, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFB45309)},
    {'label': 'Vegetarian', 'icon': Icons.hotel, 'color': AppColors.primaryLight, 'iconColor': AppColors.primaryDark},
    {'label': 'Paleo', 'icon': Icons.restaurant, 'color': Color(0xFFFFEBEE), 'iconColor': AppColors.danger},
    {'label': 'Gluten-free', 'icon': Icons.grain, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFB45309)},
    {'label': 'Dairy-free', 'icon': Icons.ac_unit, 'color': Color(0xFFE3F2FD), 'iconColor': Color(0xFF1976D2)},
    {'label': 'Pescatarian', 'icon': Icons.set_meal, 'color': Color(0xFFE3F2FD), 'iconColor': Color(0xFF1976D2)},
    {'label': 'Low Carb', 'icon': Icons.trending_down, 'color': Color(0xFFFFF3E0), 'iconColor': AppColors.danger},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('ONBOARDING',
                            style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                        Text('Step 2 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.66,
                        minHeight: 5,
                        backgroundColor: Color(0xFFCFE7D2),
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Dietary Preferences',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Select all that apply. This helps us suggest the best recipes and pantry tips for you.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (_, i) {
                        final opt = _options[i];
                        final label = opt['label'] as String;
                        final isSelected = _selected.contains(label);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selected.remove(label);
                            } else {
                              _selected.add(label);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: opt['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(opt['icon'] as IconData,
                                            color: opt['iconColor'] as Color,
                                            size: 28),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: AppColors.primaryDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can always update these preferences later in your Profile settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep3Screen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
