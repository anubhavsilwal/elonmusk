import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Anubhav Silwal');
  final _emailCtrl = TextEditingController(text: 'anubhav@shelflife.app');
  final _phoneCtrl = TextEditingController(text: '+977 98XXXXXXXX');
  final _bdayCtrl = TextEditingController(text: '07/15/1999');
  String _gender = 'Male';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bdayCtrl.dispose();
    super.dispose();
  }

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text('Edit Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text('Update your personal information.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 14)),
          const SizedBox(height: 24),
          // ---- Avatar ----
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryLight, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.chipBg(context),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/profile/avatar_default.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 56,
                          color: AppColors.textMut(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Change Photo',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'Personal Info', [
            _label(context, 'Full Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Email Address'),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Phone Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Birthdate'),
            const SizedBox(height: 6),
            TextField(
              controller: _bdayCtrl,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Gender'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(value: 'N/A', child: Text('Prefer not to say')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Password', [
            _label(context, 'Current Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Enter current password',
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'New Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_reset),
                hintText: 'At least 8 characters',
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Confirm New Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                hintText: 'Re-enter new password',
              ),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: AppColors.bg(context),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully.')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Text(
        s,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.textSec(context),
        ),
      );
}
