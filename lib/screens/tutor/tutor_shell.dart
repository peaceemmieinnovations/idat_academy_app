import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import 'tutor_dashboard_screen.dart';
import 'tutor_screens.dart';
import 'tutor_assignments_screen.dart';
import '../auth/login_screen.dart';

class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> {
  int _index = 0;

  final _screens = const [
    TutorDashboardScreen(),
    TutorLessonsScreen(),
    TutorAssignmentsScreen(),
    TutorStudentsScreen(),
    TutorAnnouncementsScreen(),
    _TutorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          if (i != _index) HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            activeIcon: Icon(Icons.upload_file_rounded),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign_rounded),
            label: 'Announce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TutorProfileTab extends StatefulWidget {
  const _TutorProfileTab();

  @override
  State<_TutorProfileTab> createState() => _TutorProfileTabState();
}

class _TutorProfileTabState extends State<_TutorProfileTab> {
  void _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = result.files.first;
      setState(() {
        _photoFile = file.path != null ? File(file.path!) : null;
        _uploadingPhoto = true;
      });
      final bytes = file.bytes;
      if (bytes != null) {
        final saved = await AuthScope.of(context).updateTutorProfile({
          'photo': base64Encode(bytes),
        });
        if (!mounted) return;
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(saved
                ? 'Profile picture uploaded'
                : 'Unable to upload profile picture. Please try again.')));
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  String? _photoUrl;
  File? _photoFile;
  bool _uploadingPhoto = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _loadFields(tutor) {
    if (_loaded || tutor == null) return;
    _firstName.text = tutor.firstName;
    _lastName.text = tutor.lastName;
    _email.text = tutor.email;
    _phone.text = tutor.phone ?? '';
    _bio.text = tutor.bio ?? '';
    _photoUrl = tutor.photo;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await AuthScope.of(context).updateTutorProfile({
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'bio': _bio.text.trim(),
      if (_photoUrl?.isNotEmpty ?? false) 'photo': _photoUrl,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved
            ? 'Profile saved'
            : 'Unable to save profile. Please try again.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final tutor = auth.tutor;
    _loadFields(tutor);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileHero(tutor),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickProfilePhoto,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(_uploadingPhoto
                      ? 'Uploading photo...'
                      : 'Upload profile photo'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'First name is required'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Last name is required'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'About me')),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save profile'))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(tutor) {
    final name = tutor?.fullName ?? 'Staff member';
    final imageUrl = _photoUrl?.trim() ?? tutor?.photo?.trim() ?? '';
    final ImageProvider? image = _photoFile != null
        ? FileImage(_photoFile!) as ImageProvider
        : imageUrl.startsWith('http')
            ? NetworkImage(imageUrl) as ImageProvider
            : null;
    final initial = (tutor?.firstName ?? 'T')[0].toUpperCase();

    return SizedBox(
      height: 210,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null) Image(image: image, fit: BoxFit.cover),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: AppColors.secondary.withValues(alpha: 0.76),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.secondary.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: CircleAvatar(
                      radius: 43,
                      backgroundColor: AppColors.primary,
                      backgroundImage: image,
                      child: image == null
                          ? Text(initial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('IDAT Academy Staff',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
