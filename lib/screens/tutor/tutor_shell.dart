import 'package:flutter/material.dart';

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
        onTap: (i) => setState(() => _index = i),
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
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose(); _email.dispose();
    _phone.dispose(); _bio.dispose();
    super.dispose();
  }

  void _loadFields(tutor) {
    if (_loaded || tutor == null) return;
    _firstName.text = tutor.firstName; _lastName.text = tutor.lastName;
    _email.text = tutor.email; _phone.text = tutor.phone ?? '';
    _bio.text = tutor.bio ?? ''; _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await AuthScope.of(context).updateTutorProfile({
      'first_name': _firstName.text.trim(), 'last_name': _lastName.text.trim(),
      'email': _email.text.trim(), 'phone': _phone.text.trim(), 'bio': _bio.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Profile saved' : 'Unable to save profile. Please try again.')));
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
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
              child: Text(
                (tutor?.firstName ?? 'T')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            TextFormField(controller: _firstName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'First name'), validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lastName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Last name'), validator: (v) => v == null || v.trim().isEmpty ? 'Last name is required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 12),
            TextFormField(controller: _bio, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'About me')),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded), label: Text(_saving ? 'Saving...' : 'Save profile'))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
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
}
