import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/gamification_service.dart';
import '../models/models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _role;
  String? _staffRole;
  Student? _student;
  Tutor? _tutor;
  String? _error;

  AuthStatus get status => _status;
  String? get role => _role;
  String? get staffRole => _staffRole;
  Student? get student => _student;
  Tutor? get tutor => _tutor;
  String? get error => _error;
  bool get isStudent => _role == 'student';
  bool get isTutor => _role == 'tutor';
  bool get isStaff => _role == 'staff';
  bool get isStaffWorkspaceUser => isTutor || isStaff;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await ApiService.getToken();
    final role = await ApiService.getRole();
    final staffRole = await ApiService.getStaffRole();
    if (token != null && role != null) {
      _role = role;
      _staffRole = staffRole;
      _status = AuthStatus.authenticated;
      await GamificationService.recordLogin();
      await NotificationService.registerCurrentDevice();
      await _loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> loginStudent(String email, String password) async {
    _error = null;
    final res = await ApiService.studentLogin(email, password);
    if (res['error'] != null) {
      _error = res['error'];
      notifyListeners();
      return false;
    }
    if (res['token'] != null) {
      await ApiService.saveToken(res['token'], 'student');
      _role = 'student';
      _staffRole = null;
      if (res['student'] != null) _student = Student.fromJson(res['student']);
      _status = AuthStatus.authenticated;
      await GamificationService.recordLogin();
      await NotificationService.registerCurrentDevice();
      notifyListeners();
      return true;
    }
    _error = res['message'] ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<bool> loginTutor(String email, String password) async {
    _error = null;
    final res = await ApiService.tutorLogin(email, password);
    if (res['error'] != null) {
      _error = res['error'];
      notifyListeners();
      return false;
    }
    if (res['token'] != null) {
      final appRole = res['app_role'] == 'staff' ? 'staff' : 'tutor';
      final staffRole = res['staff_role']?.toString() ?? 'staff';
      await ApiService.saveToken(res['token'], appRole, staffRole: staffRole);
      _role = appRole;
      _staffRole = staffRole;
      if (res['tutor'] != null) _tutor = Tutor.fromJson(res['tutor']);
      _status = AuthStatus.authenticated;
      await GamificationService.recordLogin();
      await NotificationService.registerCurrentDevice();
      notifyListeners();
      return true;
    }
    _error = res['message'] ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<void> _loadProfile() async {
    if (_role == 'student') {
      final res = await ApiService.getStudentProfile();
      final profile = res['data'] ?? res;
      if (profile is Map<String, dynamic>) {
        _student = Student.fromJson(profile);
      }
    } else if (_role == 'tutor' || _role == 'staff') {
      final res = await ApiService.getTutorProfile();
      final profile = res['data'] ?? res;
      if (profile is Map<String, dynamic>) {
        _tutor = Tutor.fromJson(profile);
      }
    }
    notifyListeners();
  }

  Future<bool> updateTutorProfile(Map<String, dynamic> data) async {
    final res = await ApiService.updateTutorProfile(data);
    if (res['error'] != null) {
      _error = res['error'].toString();
      notifyListeners();
      return false;
    }
    final profile = res['data'];
    if (profile is Map<String, dynamic>) {
      _tutor = Tutor.fromJson(profile);
    } else {
      await _loadProfile();
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await NotificationService.unregisterCurrentDevice();
    await ApiService.clearSession();
    _status = AuthStatus.unauthenticated;
    _role = null;
    _staffRole = null;
    _student = null;
    _tutor = null;
    notifyListeners();
  }
}
