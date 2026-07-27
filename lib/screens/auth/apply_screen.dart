import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _submitted = false;
  bool _agreeTerms = false;

  // Personal Information
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'Male';
  final _dobCtrl = TextEditingController();
  String _state = '';
  final _lgaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Academic Information
  String _educationLevel = '';
  final _occupationCtrl = TextEditingController();
  String _howHeard = '';

  // Course Information — up to 3
  final Set<String> _selectedCourses = {};

  // Learning Mode
  String _learningMode = 'Physical';

  // Dropdown options
  final List<String> _courses = [
    'Artificial Intelligence (AI)',
    'Crypto Masterclass',
    'Cybersecurity',
    'Data Analysis',
    'Digital Marketing',
    'Forex Trading',
    'Graphics Design & Video Editing',
    'Virtual Assistant',
    'Web Development',
    'Teens Tech Program',
  ];

  final List<String> _educationLevels = [
    '',
    'High School',
    'Diploma',
    "Bachelor's Degree",
    "Master's Degree",
    'PhD',
    'Other',
  ];

  final List<String> _hearOptions = [
    '',
    'Social Media',
    'Friend/Family',
    'Website',
    'Advertisement',
    'School/University',
    'Other',
  ];

  final List<String> _states = [
    '',
    'Abia', 'Abuja', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi',
    'Bayelsa', 'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi',
    'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna',
    'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa',
    'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers',
    'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _otherNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _lgaCtrl.dispose();
    _addressCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  bool get _courseLimitReached => _selectedCourses.length >= 3;

  void _toggleCourse(String course) {
    setState(() {
      if (_selectedCourses.contains(course)) {
        _selectedCourses.remove(course);
      } else if (!_courseLimitReached) {
        _selectedCourses.add(course);
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF283CE9),
              onPrimary: Colors.white,
              surface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_state.isEmpty) {
      _showError('Please select your state');
      return;
    }
    if (_educationLevel.isEmpty) {
      _showError('Please select your highest level of education');
      return;
    }
    if (_howHeard.isEmpty) {
      _showError('Please tell us how you heard about IDAT Academy');
      return;
    }
    if (_selectedCourses.isEmpty) {
      _showError('Please select at least one course');
      return;
    }
    if (!_agreeTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    setState(() => _loading = true);

    final data = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'other_name': _otherNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gender': _gender,
      'date_of_birth': _dobCtrl.text.trim(),
      'state': _state,
      'lga': _lgaCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'education_level': _educationLevel,
      'occupation': _occupationCtrl.text.trim(),
      'how_heard': _howHeard,
      'courses': _selectedCourses.toList(),
      'learning_mode': _learningMode,
    };

    final res = await ApiService.submitApplication(data);

    setState(() => _loading = false);

    if (res['error'] != null && mounted) {
      _showError(res['error']);
      return;
    }

    setState(() => _submitted = true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
      (_) => false,
    );
  }

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF283CE9).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF283CE9).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF283CE9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF283CE9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Male', 'Female', 'Other'].map((g) {
        final selected = _gender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: g != 'Other' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF283CE9).withValues(alpha: 0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF283CE9)
                      : AppColors.lightGrey,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  g,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF283CE9)
                        : AppColors.dark,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(String course, int index) {
    final selected = _selectedCourses.contains(course);
    return GestureDetector(
      onTap: () => _toggleCourse(course),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF283CE9).withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF283CE9)
                : AppColors.lightGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF283CE9).withValues(alpha: 0.12)
                    : AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _courseIcon(index),
                color: selected
                    ? const Color(0xFF283CE9)
                    : AppColors.textGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                course,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF283CE9)
                      : AppColors.dark,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF283CE9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.lightGrey,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _courseIcon(int index) {
    const icons = [
      Icons.psychology_rounded,
      Icons.currency_bitcoin,
      Icons.security_rounded,
      Icons.bar_chart_rounded,
      Icons.campaign_rounded,
      Icons.trending_up_rounded,
      Icons.palette_rounded,
      Icons.headset_mic_rounded,
      Icons.code_rounded,
      Icons.rocket_launch_rounded,
    ];
    return index < icons.length ? icons[index] : Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B0151),
              Color(0xFF2D0A6B),
              AppColors.scaffoldBg,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    const Text(
                      'Apply Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Fill out the form below — our admissions team reviews every application and confirms your payment before enrollment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Scrollable Form Body ─────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ══════ Personal Information ════════════════
                            _sectionHeader('Personal Information'),
                            const SizedBox(height: 16),

                            _buildLabel('First Name'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _firstNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'First Name'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Last Name'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _lastNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'Last Name'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Other Name (optional)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _otherNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'Other Name (optional)'),
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Email Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'Email Address'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email required';
                                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Phone Number'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'Phone Number'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Phone required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Gender'),
                            const SizedBox(height: 6),
                            _buildGenderSelector(),
                            const SizedBox(height: 14),

                            _buildLabel('Date of Birth'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _dobCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'mm/dd/yyyy',
                                suffixIcon: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.calendar_today_rounded,
                                      color: AppColors.textGrey, size: 18),
                                ),
                              ),
                              onTap: _pickDate,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Date of birth required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('State'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _state.isEmpty ? null : _state,
                              decoration: const InputDecoration(hintText: 'Select state'),
                              items: _states
                                  .where((s) => s.isNotEmpty)
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _state = v ?? ''),
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('LGA'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _lgaCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'LGA'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'LGA required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Residential Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _addressCtrl,
                              textInputAction: TextInputAction.next,
                              maxLines: 2,
                              decoration: const InputDecoration(hintText: 'Residential Address'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Address required' : null,
                            ),
                            const SizedBox(height: 24),

                            // ══════ Academic Information ════════════════
                            _sectionHeader('Academic Information'),
                            const SizedBox(height: 16),

                            _buildLabel('Highest Level of Education'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _educationLevel.isEmpty ? null : _educationLevel,
                              decoration: const InputDecoration(hintText: 'Select level'),
                              items: _educationLevels
                                  .where((e) => e.isNotEmpty)
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => _educationLevel = v ?? ''),
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('Occupation (optional)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _occupationCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'Occupation (optional)'),
                            ),
                            const SizedBox(height: 14),

                            _buildLabel('How did you hear about IDAT Academy?'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _howHeard.isEmpty ? null : _howHeard,
                              decoration: const InputDecoration(hintText: 'Select an option'),
                              items: _hearOptions
                                  .where((h) => h.isNotEmpty)
                                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                                  .toList(),
                              onChanged: (v) => setState(() => _howHeard = v ?? ''),
                            ),
                            const SizedBox(height: 24),

                            // ══════ Course Information ══════════════════
                            _sectionHeader('Course Information'),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF283CE9).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF283CE9).withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: Color(0xFF283CE9), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select up to 3 course(s). ${_selectedCourses.length}/3 selected.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF283CE9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Course list
                            ...List.generate(_courses.length, (i) =>
                                _buildCourseCard(_courses[i], i)),

                            if (_selectedCourses.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Please select at least one course',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // ══════ Learning Mode ═══════════════════════
                            _sectionHeader('Preferred Learning Mode'),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _modeOption('Physical', Icons.business_rounded,
                                      'Abuja Campus'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _modeOption('Online', Icons.laptop_mac_rounded,
                                      'Virtual'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ══════ Terms & Submit ══════════════════════
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                                    activeColor: const Color(0xFF283CE9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                                        children: const [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(
                                              color: Color(0xFF283CE9),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' of IDAT Academy.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            GradientButton(
                              label: 'Submit Application',
                              icon: Icons.send_rounded,
                              loading: _loading,
                              onPressed: _submitApplication,
                            ),
                            const SizedBox(height: 12),

                            Center(
                              child: GestureDetector(
                                onTap: _goToLogin,
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                                    children: const [
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: Color(0xFF283CE9),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption(String mode, IconData icon, String subtitle) {
    final selected = _learningMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _learningMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF283CE9).withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF283CE9)
                : AppColors.lightGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF283CE9)
                  : AppColors.textGrey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              mode,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: selected
                    ? const Color(0xFF283CE9)
                    : AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? const Color(0xFF283CE9).withValues(alpha: 0.7)
                    : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success Screen ─────────────────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0151), Color(0xFF283CE9)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Application\nSubmitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Thank you for applying to IDAT Academy. We\'ll review your application and get back to you within 2-3 business days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Color(0xFF1B0151),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
