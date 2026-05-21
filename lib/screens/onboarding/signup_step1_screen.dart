import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'signup_step2_screen.dart';

class SignupStep1Screen extends StatelessWidget {
  const SignupStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppLogoIcon(size: 36),
                  SizedBox(width: 8),
                  AppLogoText(height: 30),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step 1 of 3',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      )),
                  Text('Account Basics',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.33,
                  minHeight: 5,
                  backgroundColor: Color(0xFFCFE7D2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 24),
              Text('Create your account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 8),
              Text(
                "Let's start with some basic information to get your pantry organized.",
                style: TextStyle(
                    color: AppColors.textSec(context), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/onboarding/signup_pantry.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFFE9DCC4),
                    child: const Center(
                      child: Icon(Icons.kitchen, size: 64, color: Colors.brown),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _label(context, 'Full Name'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Enter your full name',
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Email Address'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'example@email.com',
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Password'),
              const SizedBox(height: 6),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Min. 8 characters',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Birthdate + Gender — use LayoutBuilder to avoid right overflow.
              LayoutBuilder(
                builder: (_, c) {
                  // On narrow screens, stack vertically. Otherwise side-by-side.
                  final stacked = c.maxWidth < 340;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context, 'Birthdate'),
                        const SizedBox(height: 6),
                        const TextField(
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(context, 'Gender'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          hint: const Text('Select'),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                            DropdownMenuItem(value: 'O', child: Text('Other')),
                            DropdownMenuItem(value: 'N', child: Text('Prefer not to say')),
                          ],
                          onChanged: (_) {},
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Birthdate'),
                            const SizedBox(height: 6),
                            const TextField(
                              decoration: InputDecoration(
                                hintText: 'mm/dd/yyyy',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Gender'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              hint: const Text('Select'),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Male')),
                                DropdownMenuItem(value: 'F', child: Text('Female')),
                                DropdownMenuItem(value: 'O', child: Text('Other')),
                                DropdownMenuItem(value: 'N', child: Text('Other...')),
                              ],
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignupStep2Screen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next Step'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: AppColors.textPri(context), fontSize: 14),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSec(context)),
                    children: const [
                      TextSpan(text: "By continuing, you agree to ShelfLife's "),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Text(
        s,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPri(context),
        ),
      );
}
