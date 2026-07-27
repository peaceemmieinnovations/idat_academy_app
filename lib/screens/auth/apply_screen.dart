import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

/// A beautiful multi-step wizard (slides) for applying to IDAT Academy.
/// Each step is a full-page slide with animations, no boring scroll form.
class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _loading = false;
  bool _submitted = false;

  late PageController _pageCtrl;
  late AnimationController _slideAnimCtrl;

  // ─── Step 1: Personal Info ────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'Male';

  // ─── Step 2: Location ─────────────────────────────────────────────────
  String _state = '';
  final _lgaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ─── Step 3: Education & Background ───────────────────────────────────
  String _educationLevel = '';
  final _occupationCtrl = TextEditingController();
  String _howHeard = '';

  // ─── Step 4: Courses & Mode ───────────────────────────────────────────
  final Set<String> _selectedCourses = {};
  String _learningMode = 'Physical';
  bool _agreeTerms = false;

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
    'High School',
    'Diploma',
    "Bachelor's Degree",
    "Master's Degree",
    'PhD',
    'Other',
  ];

  final List<String> _hearOptions = [
    'Social Media',
    'Friend/Family',
    'Website',
    'Advertisement',
    'School/University',
    'Other',
  ];

  final List<String> _states = [
    'Abia', 'Abuja', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi',
    'Bayelsa', 'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi',
    'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna',
    'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa',
    'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers',
    'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _slideAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _slideAnimCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _lgaCtrl.dispose();
    _addressCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  bool get _canProceedFromStep {
    switch (_step) {
      case 0:
        return _firstNameCtrl.text.trim().isNotEmpty &&
            _lastNameCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.contains('@') &&
            _phoneCtrl.text.trim().isNotEmpty;
      case 1:
        return _state.isNotEmpty && _lgaCtrl.text.trim().isNotEmpty;
      case 2:
        return _educationLevel.isNotEmpty && _howHeard.isNotEmpty;
      case 3:
        return _selectedCourses.isNotEmpty && _agreeTerms;
      default:
        return false;
    }
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

  void _nextStep() {
    if (_canProceedFromStep && _step < 4) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submitApplication() async {
    if (!_canProceedFromStep || _loading) return;
    setState(() => _loading = true);

    final data = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gender': _gender,
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

  /// The application flow can be opened from onboarding or from the login
  /// screen.  Always provide a real destination when it is cancelled instead
  /// of relying on the navigator history, which may be empty after splash.
  void _cancelApplication() => _goToLogin();

  // ─── Step titles & descriptions ────────────────────────────────────────
  static const _stepData = [
    _StepData(
      Icons.person_rounded,
      'Personal Info',
      'Tell us who you are — it only takes a moment.',
    ),
    _StepData(
      Icons.location_on_rounded,
      'Your Location',
      'Where are you based? We want to know if you\'re near our campus.',
    ),
    _StepData(
      Icons.school_rounded,
      'Background',
      'Your educational level and how you found us.',
    ),
    _StepData(
      Icons.menu_book_rounded,
      'Courses & Mode',
      'Pick what you want to learn and how you\'d like to study.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return WillPopScope(
      onWillPop: () async {
        _cancelApplication();
        return false;
      },
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0151), Color(0xFF283CE9), AppColors.scaffoldBg],
            stops: [0.0, 0.25, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar: Back + Step indicator ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      )
                    else
                      IconButton(
                        tooltip: 'Cancel application and return to sign in',
                        onPressed: _cancelApplication,
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    const Spacer(),
                    // Step indicator
                    Row(
                      children: List.generate(4, (i) {
                        final isActive = i <= _step;
                        final isCurrent = i == _step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 4),
                          width: isCurrent ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Step title + counter ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepData[_step].title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepData[_step].subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_step + 1} / 4',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Page view ──────────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPersonalInfo(),
                        _buildLocationStep(),
                        _buildBackgroundStep(),
                        _buildCoursesStep(),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    // Sign in text
                    if (_step == 0)
                      TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Sign In'),
                      )
                    else
                      const SizedBox.shrink(),

                    const Spacer(),

                    // Next / Submit
                    GestureDetector(
                      onTap: _loading || !_canProceedFromStep
                          ? null
                          : (_step == 3 ? _submitApplication : _nextStep),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: _canProceedFromStep
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (_canProceedFromStep)
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _loading
                                  ? 'Submitting...'
                                  : _step == 3
                                      ? 'Submit'
                                      : _step == 2
                                          ? 'Almost Done'
                                          : 'Continue',
                              style: TextStyle(
                                color: _canProceedFromStep
                                    ? AppColors.primary
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!_loading) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _step == 3
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                color: _canProceedFromStep
                                    ? AppColors.primary
                                    : Colors.white,
                                size: 20,
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ─── Step 1: Personal Info ───────────────────────────────────────────────
  Widget _buildPersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('First Name *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _firstNameCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. John'),
          ),
          const SizedBox(height: 16),
          _inputLabel('Last Name *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lastNameCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Doe'),
          ),
          const SizedBox(height: 16),
          _inputLabel('Email Address *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'john@email.com'),
          ),
          const SizedBox(height: 16),
          _inputLabel('Phone Number *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '+234...'),
          ),
          const SizedBox(height: 16),
          _inputLabel('Gender'),
          const SizedBox(height: 6),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.lightGrey,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g,
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.dark,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (!_canProceedFromStep && _step == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Fill in all required fields to continue',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 2: Location ────────────────────────────────────────────────────
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('State *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _state.isEmpty ? null : _state,
            decoration: const InputDecoration(hintText: 'Select your state'),
            items: _states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _state = v ?? ''),
          ),
          const SizedBox(height: 16),
          _inputLabel('LGA *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lgaCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Local Government Area'),
          ),
          const SizedBox(height: 16),
          _inputLabel('Residential Address *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Street, city...'),
          ),
          const SizedBox(height: 8),
          if (!_canProceedFromStep && _step == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select state and enter LGA to continue',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 3: Background ──────────────────────────────────────────────────
  Widget _buildBackgroundStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('Highest Education *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _educationLevel.isEmpty ? null : _educationLevel,
            decoration: const InputDecoration(hintText: 'Select level'),
            items: _educationLevels
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _educationLevel = v ?? ''),
          ),
          const SizedBox(height: 16),
          _inputLabel('Occupation (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _occupationCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'e.g. Student, Developer'),
          ),
          const SizedBox(height: 16),
          _inputLabel('How did you hear about us? *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _howHeard.isEmpty ? null : _howHeard,
            decoration: const InputDecoration(hintText: 'Select an option'),
            items: _hearOptions
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _howHeard = v ?? ''),
          ),
          const SizedBox(height: 8),
          if (!_canProceedFromStep && _step == 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select education & referral source to continue',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 4: Courses ─────────────────────────────────────────────────────
  Widget _buildCoursesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pick up to 3 courses. ${_selectedCourses.length}/3 selected.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(_courses.length, (i) => _buildCourseChip(_courses[i], i)),

          const SizedBox(height: 20),

          // Learning mode
          _inputLabel('Learning Mode'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _modeOption('Physical', Icons.business_rounded, 'Campus')),
              const SizedBox(width: 12),
              Expanded(child: _modeOption('Online', Icons.laptop_mac_rounded, 'Virtual')),
            ],
          ),
          const SizedBox(height: 20),

          // Terms
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24, width: 24,
                child: Checkbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I agree to the Terms & Conditions of IDAT Academy.',
                  style: TextStyle(fontSize: 13, color: AppColors.dark, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseChip(String course, int index) {
    final selected = _selectedCourses.contains(course);
    return GestureDetector(
      onTap: () => _toggleCourse(course),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.lightGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _courseIcon(index),
                color: selected ? AppColors.primary : AppColors.textGrey,
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
                  color: selected ? AppColors.primary : AppColors.dark,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGrey, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeOption(String mode, IconData icon, String subtitle) {
    final selected = _learningMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _learningMode = mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.lightGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textGrey, size: 28),
            const SizedBox(height: 6),
            Text(
              mode,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? AppColors.primary : AppColors.dark,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: selected ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textGrey),
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

  Widget _inputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    );
  }

  // ─── Success screen ──────────────────────────────────────────────────────
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
              // Animated check
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 3),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Application\nSubmitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Text(
                  'Thank you for applying to IDAT Academy. We\'ll review and get back to you within 2-3 business days.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Sign In to Dashboard',
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

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepData(this.icon, this.title, this.subtitle);
}
