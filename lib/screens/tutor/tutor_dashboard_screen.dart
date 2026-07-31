import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/models.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'tutor_screens.dart';
import 'tutor_shell.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  TutorDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  // Attendance state
  bool _attendanceClockedIn = false;
  DateTime? _attendanceClockInTime;
  String _attendancePlan = '';
  String _attendanceReport = '';
  bool _attendancePlanSubmitted = false;
  bool _attendanceReportSubmitted = false;
  bool _attendanceClockedOut = false;
  Duration _attendanceElapsed = Duration.zero;
  Timer? _attendanceTimer;
  bool _attendanceSubmitting = false;

  // Scanner
  bool _showScanner = false;
  bool _scanningForClockIn = true;
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _scannerActive = false;
  String? _attendanceQrToken;

  @override
  void initState() {
    super.initState();
    _load();
    _restoreAttendance();
  }

  @override
  void dispose() {
    _attendanceTimer?.cancel();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getTutorDashboard();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        setState(() {
          _dashboard = TutorDashboard.fromJson(res);
          _loading = false;
        });
      }
    }
  }

  Future<void> _restoreAttendance() async {
    final session = await StaffAttendanceSession.restore();
    if (session != null && mounted) {
      final clockIn = DateTime.parse(session['clock_in']);
      final elapsed = DateTime.now().difference(clockIn);
      setState(() {
        _attendanceClockedIn = true;
        _attendanceClockInTime = clockIn;
        _attendancePlan = session['plan'] ?? '';
        _attendanceReport = session['report'] ?? '';
        _attendancePlanSubmitted = (session['plan']?.toString().isNotEmpty == true);
        _attendanceReportSubmitted = (session['report']?.toString().isNotEmpty == true);
        _attendanceElapsed = elapsed;
      });
      _startAttendanceTimer();
    }
  }

  void _startAttendanceTimer() {
    _attendanceTimer?.cancel();
    _attendanceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _attendanceClockInTime != null && !_attendanceClockedOut) {
        setState(() => _attendanceElapsed = DateTime.now().difference(_attendanceClockInTime!));
      }
    });
  }

  void _openScanner(bool forClockIn) {
    setState(() {
      _scanningForClockIn = forClockIn;
      _showScanner = true;
      _scannerActive = true;
    });
    _scannerCtrl.start();
  }

  void _closeScanner() {
    setState(() { _showScanner = false; _scannerActive = false; });
    _scannerCtrl.stop();
  }

  void _onAttendanceDetect(BarcodeCapture capture) {
    if (!_scannerActive) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _attendanceQrToken = barcode!.rawValue;
      setState(() => _scannerActive = false);
      _scannerCtrl.stop();
      if (_scanningForClockIn) {
        _handleClockInScan();
      } else {
        _handleClockOutScan();
      }
    }
  }

  Future<void> _handleClockInScan() async {
    setState(() => _attendanceSubmitting = true);
    final res = await ApiService.post('staff/attendance/clock-in', {
      'action': 'clock_in',
      'qr_token': _attendanceQrToken,
    });
    if (res['error'] != null) {
      if (mounted) {
        setState(() => _attendanceSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    final now = DateTime.now();
    await StaffAttendanceSession.save(now, '');
    if (mounted) {
      setState(() {
        _attendanceClockedIn = true;
        _attendanceClockInTime = now;
        _attendanceSubmitting = false;
        _showScanner = false;
      });
      _startAttendanceTimer();
    }
  }

  Future<void> _submitPlan() async {
    final plan = await showDialog<String>(
      context: context,
      builder: (ctx) => _AttendanceFormDialog(
        title: "Today's Plan",
        hint: 'What do you plan to do today?',
        initialValue: _attendancePlan,
      ),
    );
    if (plan == null || plan.trim().isEmpty) return;
    setState(() => _attendanceSubmitting = true);
    await ApiService.post('staff/attendance/plan', {'plan': plan});
    await StaffAttendanceSession.save(_attendanceClockInTime!, plan);
    if (mounted) {
      setState(() {
        _attendancePlan = plan;
        _attendancePlanSubmitted = true;
        _attendanceSubmitting = false;
      });
    }
  }

  Future<void> _submitReport() async {
    final report = await showDialog<String>(
      context: context,
      builder: (ctx) => _AttendanceFormDialog(
        title: 'End of Day Report',
        hint: 'Write your report before clocking out...',
        initialValue: _attendanceReport,
        maxLines: 6,
      ),
    );
    if (report == null || report.trim().isEmpty) return;
    setState(() => _attendanceSubmitting = true);
    await ApiService.post('staff/attendance/report', {'report': report});
    final storage = const FlutterSecureStorage();
    final raw = await storage.read(key: 'staff_attendance');
    if (raw != null) {
      final data = jsonDecode(raw);
      data['report'] = report;
      await storage.write(key: 'staff_attendance', value: jsonEncode(data));
    }
    if (mounted) {
      setState(() {
        _attendanceReport = report;
        _attendanceReportSubmitted = true;
        _attendanceSubmitting = false;
      });
    }
  }

  Future<void> _handleClockOutScan() async {
    setState(() => _attendanceSubmitting = true);
    final res = await ApiService.post('staff/attendance/clock-out', {
      'action': 'clock_out',
      'qr_token': _attendanceQrToken,
    });
    if (res['error'] != null) {
      if (mounted) {
        setState(() => _attendanceSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    await StaffAttendanceSession.clear();
    if (mounted) {
      setState(() {
        _attendanceClockedOut = true;
        _attendanceSubmitting = false;
        _showScanner = false;
      });
      _attendanceTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final tutor = auth.tutor;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            color: AppColors.secondary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 170,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.campaign_rounded, color: Colors.white),
                      tooltip: 'Announcements',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorAnnouncementsScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_rounded, color: Colors.white),
                      tooltip: 'Profile',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorProfileScreen())),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tutor Portal',
                                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text(
                                          tutor != null ? 'Hello, ${tutor.firstName}!' : 'Hello!',
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      (tutor?.firstName ?? 'T')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: const Text('Dashboard'),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: ErrorState(message: _error!, onRetry: _load),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                          children: [
                            StatCard(label: 'My Students', value: '${_dashboard?.totalStudents ?? 0}',
                                icon: Icons.people_rounded, color: AppColors.secondary),
                            StatCard(label: 'My Courses', value: '${_dashboard?.totalCourses ?? 0}',
                                icon: Icons.menu_book_rounded, color: AppColors.success),
                            StatCard(label: 'Pending Reviews', value: '${_dashboard?.pendingSubmissions ?? 0}',
                                icon: Icons.pending_actions_rounded, color: AppColors.warning),
                            StatCard(label: 'Total Lessons', value: '${_dashboard?.totalLessons ?? 0}',
                                icon: Icons.video_library_rounded, color: AppColors.accent),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildAttendanceSection(),
                        const SizedBox(height: 28),
                        if (_dashboard?.courses.isNotEmpty == true) ...[
                          const SectionHeader(title: 'My Courses'),
                          const SizedBox(height: 12),
                          ..._dashboard!.courses.map((c) => CourseCard(course: c)).toList(),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          if (_showScanner)
            _buildScannerOverlay(),
        ],
      ),
    );
  }

  // ─── Attendance Section ──────────────────────────────────────────────────────

  Widget _buildAttendanceSection() {
    if (_attendanceClockedOut) {
      return _buildClockedOutCard();
    }
    if (!_attendanceClockedIn) {
      return _buildClockInPrompt();
    }
    return _buildActiveAttendanceCard();
  }

  Widget _buildClockInPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B0151), Color(0xFF283CE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B0151).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff Attendance', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Scan QR code to clock in for the day', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _attendanceSubmitting ? null : () => _openScanner(true),
              icon: _attendanceSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.qr_code_scanner_rounded),
              label: Text(_attendanceSubmitting ? 'Processing...' : 'Scan to Clock In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B0151),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _attendanceReportSubmitted
              ? [const Color(0xFF065F46), const Color(0xFF059669)]
              : _attendancePlanSubmitted
                  ? [const Color(0xFF1B0151), const Color(0xFF283CE9)]
                  : [const Color(0xFF92400E), const Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Active', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(_formatDuration(_attendanceElapsed),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Steps
          _stepRow(0, 'Clocked in at ${_formatTime(_attendanceClockInTime)}', true),
          _stepRow(1, 'Submit today\'s plan', _attendancePlanSubmitted, onTap: _attendancePlanSubmitted ? null : _submitPlan),
          _stepRow(2, 'Submit end-of-day report', _attendanceReportSubmitted, onTap: _attendanceReportSubmitted ? null : _submitReport),
          _stepRow(3, 'Scan QR to clock out',
              _attendanceReportSubmitted && _attendancePlanSubmitted,
              isLast: true,
              onTap: (_attendancePlanSubmitted && _attendanceReportSubmitted)
                  ? () => _openScanner(false)
                  : null),
          if (_attendanceSubmitting)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _stepRow(int index, String label, bool done, {VoidCallback? onTap, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: done ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onTap != null && !done
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done ? AppColors.success : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text('${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      color: done ? Colors.white70 : Colors.white,
                      fontSize: 13,
                      fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
              ),
              if (onTap != null && !done)
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockedOutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 14),
          const Text('Attendance complete for today',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Total time: ${_formatDuration(_attendanceElapsed)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Scanner Overlay ─────────────────────────────────────────────────────────

  Widget _buildScannerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeScanner,
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      _scanningForClockIn ? 'Clock In' : 'Clock Out',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: MobileScanner(
                            controller: _scannerCtrl,
                            onDetect: _onAttendanceDetect,
                            overlayBuilder: (context, constraints) {
                              return Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text('Scan Staff QR Code',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _scanningForClockIn
                            ? 'Scan the staff attendance QR code\nto clock in for the day'
                            : 'Scan the same QR code again\nto clock out',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                      ),
                      if (_attendanceSubmitting)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Attendance Form Dialog ────────────────────────────────────────────────────

class _AttendanceFormDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initialValue;
  final int maxLines;
  const _AttendanceFormDialog({
    required this.title,
    required this.hint,
    this.initialValue = '',
    this.maxLines = 4,
  });

  @override
  State<_AttendanceFormDialog> createState() => _AttendanceFormDialogState();
}

class _AttendanceFormDialogState extends State<_AttendanceFormDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
