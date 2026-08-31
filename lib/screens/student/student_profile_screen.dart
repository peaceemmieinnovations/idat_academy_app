import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../auth/login_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Uint8List? _avatarBytes;
  IconData? _selectedAvatar;
  bool _loading = false;
  bool _saving = false;

  // Change password
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final res = await ApiService.getStudentProfile();
    if (mounted && res['data'] != null) {
      final data = res['data'];
      _firstNameCtrl.text = data['first_name'] ?? '';
      _lastNameCtrl.text = data['last_name'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profileData = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    };
    final res = await ApiService.updateStudentProfile(profileData);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] == null ? 'Profile updated!' : res['error']),
        backgroundColor:
            res['error'] == null ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes != null && mounted) {
      setState(() {
        _avatarBytes = bytes;
        _selectedAvatar = null;
      });
    }
  }

  Future<void> _showAvatarPicker() async {
    const avatars = [
      Icons.school_rounded,
      Icons.auto_awesome_rounded,
      Icons.code_rounded,
      Icons.psychology_rounded,
      Icons.rocket_launch_rounded,
      Icons.emoji_events_rounded,
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose your profile photo', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              const Text('Upload a picture or select an avatar.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8EEFF),
                  child: Icon(Icons.add_a_photo_rounded,
                      color: AppColors.secondary),
                ),
                title: const Text('Add a photo'),
                subtitle: const Text('Choose an image from your device'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickPhoto();
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: avatars
                    .map((icon) => InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            setState(() {
                              _selectedAvatar = icon;
                              _avatarBytes = null;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: icon == _selectedAvatar
                                ? AppColors.secondary
                                : AppColors.secondary.withValues(alpha: 0.12),
                            child: Icon(icon,
                                color: icon == _selectedAvatar
                                    ? Colors.white
                                    : AppColors.secondary),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error));
      return;
    }
    final res = await ApiService.changeStudentPassword({
      'current_password': _oldPassCtrl.text,
      'new_password': _newPassCtrl.text,
      'new_password_confirmation': _confirmPassCtrl.text,
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            res['error'] == null ? 'Password changed!' : res['error'] ?? ''),
        backgroundColor:
            res['error'] == null ? AppColors.success : AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final student = auth.student;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor:
                                    AppColors.secondary.withValues(alpha: 0.15),
                                backgroundImage: _avatarBytes == null
                                    ? null
                                    : MemoryImage(_avatarBytes!),
                                child: _avatarBytes != null
                                    ? null
                                    : _selectedAvatar != null
                                        ? Icon(_selectedAvatar!,
                                            size: 38,
                                            color: AppColors.secondary)
                                        : Text(
                                            (_firstNameCtrl.text.isNotEmpty
                                                    ? _firstNameCtrl.text
                                                    : student?.firstName ??
                                                        'S')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.secondary),
                                          ),
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Material(
                                  color: AppColors.secondary,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: 'Change profile photo',
                                    onPressed: _showAvatarPicker,
                                    icon: const Icon(Icons.edit_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                              '${_firstNameCtrl.text} ${_lastNameCtrl.text}'
                                  .trim(),
                              style: AppTextStyles.h3),
                          Text(student?.email ?? '',
                              style: AppTextStyles.bodySmall),
                          const SizedBox(height: 6),
                          StatusChip.fromStatus(student?.status ?? 'active'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Edit Profile', style: AppTextStyles.h4),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lastNameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Save Changes',
                      icon: Icons.save_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Change password
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightGrey,
                        child: Icon(Icons.lock_outline_rounded,
                            color: AppColors.dark, size: 20),
                      ),
                      title: const Text('Change Password',
                          style: AppTextStyles.h4),
                      subtitle: const Text('Update your account password',
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showChangePasswordSheet(),
                    ),
                    const SizedBox(height: 8),
                    // Logout
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE5E5),
                        child: Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 20),
                      ),
                      title: const Text('Sign Out',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text('Log out of your account',
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _confirmLogout(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            TextField(
              controller: _oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm New Password'),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Update Password',
              onPressed: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthScope.of(context).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
