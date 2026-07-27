import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

/// Tutor Clock-In screen with QR code scanning.
/// Used when a tutor starts a course session.
class TutorClockInScreen extends StatefulWidget {
  final String courseTitle;
  final int courseId;

  const TutorClockInScreen({
    super.key,
    required this.courseTitle,
    required this.courseId,
  });

  @override
  State<TutorClockInScreen> createState() => _TutorClockInScreenState();
}

class _TutorClockInScreenState extends State<TutorClockInScreen>
    with TickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _scannerActive = true;
  bool _clockedIn = false;
  bool _submitting = false;
  bool _showManual = false;

  // Outline fields
  final _topicCtrl = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _keyPointsCtrl = TextEditingController();
  final _activitiesCtrl = TextEditingController();
  final _assignmentCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _animCtrl.dispose();
    _topicCtrl.dispose();
    _objectivesCtrl.dispose();
    _keyPointsCtrl.dispose();
    _activitiesCtrl.dispose();
    _assignmentCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scannerActive || _clockedIn) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final code = barcode!.rawValue!;
      // Verify it's a valid course scan code
      if (code.startsWith('IDAT-COURSE-')) {
        final scannedId = int.tryParse(code.replaceAll('IDAT-COURSE-', ''));
        if (scannedId == widget.courseId) {
          _clockInSuccess();
        } else {
          _showError('Invalid QR code for this course');
        }
      } else if (code == 'IDAT-CLOCKIN') {
        _clockInSuccess();
      } else {
        _showError('Unknown QR code');
      }
    }
  }

  void _clockInSuccess() {
    setState(() => _scannerActive = false);
    _animCtrl.forward();
    _submitClockIn();
  }

  Future<void> _submitClockIn() async {
    setState(() => _submitting = true);

    await Future.delayed(const Duration(seconds: 1));

    final res = await ApiService.post('tutor/clock-in', {
      'course_id': widget.courseId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() {
        _clockedIn = true;
        _submitting = false;
      });
    }
  }

  Future<void> _submitOutline() async {
    if (_topicCtrl.text.trim().isEmpty) {
      _showError('Please enter the lesson topic');
      return;
    }

    setState(() => _submitting = true);

    final data = {
      'course_id': widget.courseId,
      'topic': _topicCtrl.text.trim(),
      'objectives': _objectivesCtrl.text.trim(),
      'key_points': _keyPointsCtrl.text.trim(),
      'activities': _activitiesCtrl.text.trim(),
      'assignment': _assignmentCtrl.text.trim(),
    };

    final res = await ApiService.post('tutor/lesson-outline', data);

    if (mounted) {
      setState(() => _submitting = false);
      if (res['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson outline saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, {'outline_saved': true, 'clocked_in': true});
      } else {
        _showError(res['error']);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0151), Color(0xFF283CE9)],
          ),
        ),
        child: SafeArea(
          child: _clockedIn ? _buildOutlineForm() : _buildScanView(),
        ),
      ),
    );
  }

  Widget _buildScanView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'Clock In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Course info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Starting Session',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(widget.courseTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Scanner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: MobileScanner(
              controller: _scannerCtrl,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                return Stack(
                  children: [
                    // Scanning frame
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Scan QR Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Instructions
        Text(
          'Point your camera at the course QR code\nto clock in for this session',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // Manual entry toggle
        GestureDetector(
          onTap: () => setState(() => _showManual = !_showManual),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showManual
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                _showManual ? 'Hide manual entry' : 'Enter code manually',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Manual code entry
        if (_showManual) _buildManualEntry(),

        // Loading
        if (_submitting)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildManualEntry() {
    final codeCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        children: [
          TextField(
            controller: codeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter course code',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (codeCtrl.text.trim().isNotEmpty) {
                _clockInSuccess();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Clock In',
                  style: TextStyle(
                    color: Color(0xFF1B0151),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Clock-in success + outline form ─────────────────────────────────────
  Widget _buildOutlineForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Success animation
          ScaleTransition(
            scale: _checkAnim,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Clocked In!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record the lesson outline for this session',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          // Outline form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lesson Outline',
                    style: AppTextStyles.h3),
                const SizedBox(height: 16),

                _outlineField('Topic / Title *', _topicCtrl,
                    hint: 'e.g. Introduction to Neural Networks'),
                const SizedBox(height: 14),
                _outlineField('Learning Objectives',
                    _objectivesCtrl,
                    hint: 'What will students learn?', maxLines: 3),
                const SizedBox(height: 14),
                _outlineField('Key Points to Cover',
                    _keyPointsCtrl,
                    hint: 'Main concepts, one per line', maxLines: 4),
                const SizedBox(height: 14),
                _outlineField('Class Activities',
                    _activitiesCtrl,
                    hint: 'Exercises, discussions, group work', maxLines: 3),
                const SizedBox(height: 14),
                _outlineField('Assignment / Take-home',
                    _assignmentCtrl,
                    hint: 'What students should do after class', maxLines: 2),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, {'clocked_in': true}),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGrey),
                          ),
                          child: const Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _submitOutline,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF1B0151)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Outline',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

/// A simpler way to show clock-in from anywhere in tutor screens.
class TutorClockInCard extends StatelessWidget {
  final String courseTitle;
  final int courseId;

  const TutorClockInCard({
    super.key,
    required this.courseTitle,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TutorClockInScreen(
              courseTitle: courseTitle,
              courseId: courseId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1B0151)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clock In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    courseTitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
