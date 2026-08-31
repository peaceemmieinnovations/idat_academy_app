import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

/// Persists clock-in sessions per course so they survive app restarts.
class ClockInSession {
  static const _storage = FlutterSecureStorage();

  static String _key(int courseId) => 'active_clock_in_$courseId';

  static Future<void> save(int courseId, String courseTitle, DateTime clockInTime) async {
    await _storage.write(key: _key(courseId), value: jsonEncode({
      'course_id': courseId,
      'course_title': courseTitle,
      'clock_in': clockInTime.toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> restore(int courseId) async {
    final data = await _storage.read(key: _key(courseId));
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clear(int courseId) async {
    await _storage.delete(key: _key(courseId));
  }

  static Future<Map<int, Map<String, dynamic>>> restoreAll() async {
    final all = <int, Map<String, dynamic>>{};
    final keys = await _storage.readAll();
    for (final entry in keys.entries) {
      if (entry.key.startsWith('active_clock_in_')) {
        final courseId = int.tryParse(entry.key.split('_').last);
        if (courseId != null) {
          all[courseId] = jsonDecode(entry.value) as Map<String, dynamic>;
        }
      }
    }
    return all;
  }
}

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
  bool _scanningForCheckout = false;
  bool _outlineSaved = false;
  bool _clockedOut = false;
  bool _submitting = false;
  bool _showManual = false;
  String? _qrToken;
  DateTime? _clockInTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Outline fields
  final _topicCtrl = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _keyPointsCtrl = TextEditingController();
  final _activitiesCtrl = TextEditingController();
  final _assignmentCtrl = TextEditingController();

  // Manual code entry
  final _codeCtrl = TextEditingController();

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
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await ClockInSession.restore(widget.courseId);
    if (session != null && mounted) {
      final clockIn = DateTime.parse(session['clock_in']);
      final savedCourseId = session['course_id'] as int;
      final savedTitle = session['course_title'] as String;
      final elapsed = DateTime.now().difference(clockIn);
      setState(() {
        _clockedIn = true;
        _clockInTime = clockIn;
        _outlineSaved = true;
        _elapsed = elapsed;
      });
      _startTimer();
      if (savedCourseId != widget.courseId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Continuing session for "$savedTitle"'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ));
          }
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _clockInTime != null && !_clockedOut) {
        setState(() => _elapsed = DateTime.now().difference(_clockInTime!));
      }
    });
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _timer?.cancel();
    _animCtrl.dispose();
    _topicCtrl.dispose();
    _objectivesCtrl.dispose();
    _keyPointsCtrl.dispose();
    _activitiesCtrl.dispose();
    _assignmentCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scannerActive) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final code = barcode!.rawValue!;
      // The server validates the signed staff QR credential. Do not rely on
      // a client-side placeholder code, which cannot prove attendance.
      _qrToken = code;
      _scanningForCheckout ? _clockOutSuccess() : _clockInSuccess();
    }
  }

  void _clockInSuccess() {
    setState(() => _scannerActive = false);
    _animCtrl.forward();
    _submitClockIn();
  }

  void _clockOutSuccess() {
    setState(() => _scannerActive = false);
    _submitClockOut();
  }

  Future<void> _submitClockIn() async {
    setState(() => _submitting = true);

    await Future.delayed(const Duration(seconds: 1));

    final res = await ApiService.post('tutor/clock-in', {
      'action': 'clock_in',
      'qr_token': _qrToken,
      'course_id': widget.courseId,
    });
    if (res['error'] != null) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError(res['error'].toString());
      }
      return;
    }

    final now = DateTime.now();
    await ClockInSession.save(widget.courseId, widget.courseTitle, now);

    if (mounted) {
      setState(() {
        _clockedIn = true;
        _clockInTime = now;
        _submitting = false;
      });
      _startTimer();
    }
  }

  Future<void> _submitClockOut() async {
    setState(() => _submitting = true);
    final res = await ApiService.post('tutor/clock-out', {
      'action': 'clock_out',
      'qr_token': _qrToken,
      'course_id': widget.courseId,
    });
    if (res['error'] == null) await ClockInSession.clear(widget.courseId);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _clockedOut = res['error'] == null;
    });
    if (res['error'] != null) _showError(res['error']);
  }

  void _openCheckoutScanner() {
    _codeCtrl.clear();
    setState(() {
      _scanningForCheckout = true;
      _scannerActive = true;
      _showManual = false;
    });
    _scannerCtrl.start();
  }

  Future<void> _submitOutline() async {
    if (_topicCtrl.text.trim().isEmpty) {
      _showError('Please enter the lesson topic');
      return;
    }

    setState(() => _submitting = true);

    final outlineContent = [
      if (_keyPointsCtrl.text.trim().isNotEmpty)
        'Key points:\n${_keyPointsCtrl.text.trim()}',
      if (_activitiesCtrl.text.trim().isNotEmpty)
        'Class activities:\n${_activitiesCtrl.text.trim()}',
      if (_assignmentCtrl.text.trim().isNotEmpty)
        'Assignment / take-home:\n${_assignmentCtrl.text.trim()}',
    ].join('\n\n');

    final data = {
      'course_id': widget.courseId,
      'title': _topicCtrl.text.trim(),
      'objectives': _objectivesCtrl.text.trim(),
      'outline_content': outlineContent,
      if (ApiService.tutorId != null) 'tutor_id': ApiService.tutorId,
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
        setState(() => _outlineSaved = true);
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
          child: _clockedOut
              ? _buildClockedOutView()
              : _scanningForCheckout || !_clockedIn
                  ? _buildScanView()
                  : _outlineSaved
                      ? _buildActiveSessionView()
                      : _buildOutlineForm(),
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
              Text(
                _scanningForCheckout ? 'Clock Out' : 'Clock In',
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
                    Text(
                        _scanningForCheckout
                            ? 'Finishing Session'
                            : 'Starting Session',
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
          _scanningForCheckout
              ? 'Scan the same course QR code again\nto clock out and finish this session'
              : 'Point your camera at the course QR code\nto clock in for this session',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        children: [
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter course code',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
              if (_codeCtrl.text.trim().isNotEmpty) {
                final code = _codeCtrl.text.trim();
                _qrToken = code;
                if (_scanningForCheckout) {
                  _clockOutSuccess();
                } else {
                  _clockInSuccess();
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _scanningForCheckout ? 'Clock Out' : 'Clock In',
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
    if (_topicCtrl.text.isEmpty) {
      _topicCtrl.text = widget.courseTitle;
    }
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
                const Text('Lesson Outline', style: AppTextStyles.h3),
                const SizedBox(height: 16),

                _outlineField('Topic / Title *', _topicCtrl,
                    hint: 'e.g. Introduction to Neural Networks'),
                const SizedBox(height: 14),
                _outlineField('Learning Objectives', _objectivesCtrl,
                    hint: 'What will students learn?', maxLines: 3),
                const SizedBox(height: 14),
                _outlineField('Key Points to Cover', _keyPointsCtrl,
                    hint: 'Main concepts, one per line', maxLines: 4),
                const SizedBox(height: 14),
                _outlineField('Class Activities', _activitiesCtrl,
                    hint: 'Exercises, discussions, group work', maxLines: 3),
                const SizedBox(height: 14),
                _outlineField('Assignment / Take-home', _assignmentCtrl,
                    hint: 'What students should do after class', maxLines: 2),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _outlineSaved = true),
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

  Widget _buildActiveSessionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_rounded, color: Colors.white, size: 56),
          const SizedBox(height: 16),
          const Text('Session in progress',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(widget.courseTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 15)),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Column(children: [
              Text(_formatElapsed(_elapsed),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('TIME ON THIS COURSE',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ]),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openCheckoutScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Finish tasks & scan to clock out'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 17)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Your time continues until you scan the same course QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildClockedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.task_alt_rounded, color: Colors.white, size: 72),
          const SizedBox(height: 20),
          const Text('Session clocked out',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('${widget.courseTitle}\n${_formatElapsed(_elapsed)} recorded',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5)),
          const SizedBox(height: 30),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, {'clocked_out': true}),
              child: const Text('Back to dashboard')),
        ]),
      ),
    );
  }

  String _formatElapsed(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.inHours)}:${two(value.inMinutes.remainder(60))}:${two(value.inSeconds.remainder(60))}';
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
