import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'mock_data.dart';

class ApiService {
  // Change this to your server's IP/domain
  static const String baseUrl = 'http://192.168.18.20/idat-academy-portal/api';
  static const String apiKey = 'idat_live_k8x2m9p4q7w1e5r3t6y0u';

  // Track whether we're in offline mode to avoid repeated attempts
  static bool _offlineMode = false;

  static const _storage = FlutterSecureStorage();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check if an error response indicates the API is unreachable.
  static bool _isNetworkError(Map<String, dynamic> res) {
    final err = res['error']?.toString() ?? '';
    return err.contains('SocketException') ||
        err.contains('TimeoutException') ||
        err.contains('HttpException') ||
        err.contains('Connection refused') ||
        err.contains('No address') ||
        err.contains('Failed host lookup');
  }

  /// Request helper that falls back to a mock supplier on network failure.
  static Future<Map<String, dynamic>> _request(
    Future<Map<String, dynamic>> Function() apiCall, {
    required Map<String, dynamic> Function() mockFallback,
  }) async {
    // If we already know the server is unreachable this session, skip API
    if (_offlineMode) return mockFallback();

    try {
      final res = await apiCall();
      if (_isNetworkError(res)) {
        _offlineMode = true;
        return mockFallback();
      }
      return res;
    } on TimeoutException {
      _offlineMode = true;
      return mockFallback();
    } on SocketException {
      _offlineMode = true;
      return mockFallback();
    } on HttpException {
      _offlineMode = true;
      return mockFallback();
    } catch (e) {
      _offlineMode = true;
      return mockFallback();
    }
  }

  /// Reset offline mode (e.g. on logout)
  static void resetOfflineMode() {
    _offlineMode = false;
  }

  static bool get isOffline => _offlineMode;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> studentLogin(
      String email, String password) async {
    // Check demo credentials first
    if (email == MockData.studentEmail && password == MockData.password) {
      return MockData.studentLogin();
    }
    if (email == MockData.tutorEmail && password == MockData.password) {
      // Return student token structure so auto-login works; actual demo
      // login for tutor is handled separately
      return MockData.studentLogin();
    }

    return _request(() async {
      final res = await http
          .post(
            Uri.parse('$baseUrl/student/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    }, mockFallback: MockData.studentLogin);
  }

  static Future<Map<String, dynamic>> tutorLogin(
      String email, String password) async {
    // Check demo credentials first
    if (email == MockData.tutorEmail && password == MockData.password) {
      return MockData.tutorLogin();
    }

    return _request(() async {
      final res = await http
          .post(
            Uri.parse('$baseUrl/tutor/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    }, mockFallback: MockData.tutorLogin);
  }

  static Future<void> saveToken(String token, String role) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<void> clearSession() async {
    resetOfflineMode();
    await _storage.deleteAll();
  }

  static Future<String?> getToken() => _storage.read(key: 'auth_token');
  static Future<String?> getRole() => _storage.read(key: 'user_role');

  // ─── Generic GET ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? params}) async {
    return _request(() async {
      var uri = Uri.parse('$baseUrl/$endpoint');
      if (params != null) uri = uri.replace(queryParameters: params);
      final headers = await _authHeaders();
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    }, mockFallback: () => _mockGet(endpoint, params));
  }

  static Future<Map<String, dynamic>> post(String endpoint,
      Map<String, dynamic> body) async {
    return _request(() async {
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    }, mockFallback: () => _mockPost(endpoint, body));
  }

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    return _request(() async {
      final headers = await _authHeaders();
      final res = await http
          .put(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    }, mockFallback: () => _mockPost(endpoint, body));
  }

  // ─── File upload ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(
      String endpoint, File file, Map<String, String> fields) async {
    return _request(() async {
      final token = await _storage.read(key: 'auth_token');
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));
      request.headers['X-API-Key'] = apiKey;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files
          .add(await http.MultipartFile.fromPath('file', file.path));
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return jsonDecode(res.body);
    }, mockFallback: () => {'message': 'File saved (offline mode)'});
  }

  // ─── Mock router for GET ─────────────────────────────────────────────────

  static Map<String, dynamic> _mockGet(
      String endpoint, Map<String, String>? params) {
    switch (endpoint) {
      case 'student/dashboard':
        return MockData.studentDashboard();
      case 'student/courses':
        return MockData.studentCourses();
      case 'student/profile':
        return MockData.studentProfile();
      case 'student/assignments':
        return MockData.studentAssignments();
      case 'student/results':
        return MockData.studentResults();
      case 'student/certificates':
        return MockData.studentCertificates();
      case 'student/notifications':
        return MockData.studentNotifications();
      case 'tutor/dashboard':
        return MockData.tutorDashboard();
      case 'tutor/courses':
        return MockData.tutorCourses();
      case 'tutor/assignments':
        return MockData.tutorAssignments();
      case 'tutor/students':
        return MockData.tutorStudents();
      case 'tutor/profile':
        return MockData.tutorProfile();
      default:
        // Handle student/lessons?course_id=...
        if (endpoint == 'student/lessons' && params != null) {
          final courseId = int.tryParse(params['course_id'] ?? '') ?? 0;
          return MockData.lessons(courseId);
        }
        if (endpoint == 'tutor/lessons' && params != null) {
          final courseId = int.tryParse(params['course_id'] ?? '') ?? 0;
          return MockData.lessons(courseId);
        }
        // Handle tutor/submissions?assignment_id=...
        if (endpoint.startsWith('tutor/submissions')) {
          final assignmentId =
              int.tryParse(params?['assignment_id'] ?? '') ?? 1;
          return MockData.tutorSubmissions(assignmentId);
        }
        return {'data': []};
    }
  }

  // ─── Mock router for POST/PUT ────────────────────────────────────────────

  static Map<String, dynamic> _mockPost(
      String endpoint, Map<String, dynamic>? body) {
    // Mark notification as read
    if (endpoint.startsWith('student/notifications/')) {
      return {'message': 'Notification marked as read'};
    }
    // Change password
    if (endpoint == 'student/change-password') {
      return {'message': 'Password changed successfully'};
    }
    // Update profile
    if (endpoint == 'student/profile') {
      return {'message': 'Profile updated', 'data': body ?? {}};
    }
    // Submit assignment
    if (endpoint.contains('/submit')) {
      return {'message': 'Assignment submitted successfully'};
    }
    // Create assignment (tutor)
    if (endpoint == 'tutor/assignments') {
      return {'message': 'Assignment created', 'data': body ?? {}};
    }
    // Grade submission (tutor)
    if (endpoint.startsWith('tutor/submissions/')) {
      return {'message': 'Grade saved', 'data': body ?? {}};
    }
    // Upload lesson (tutor)
    if (endpoint == 'tutor/lessons') {
      return {'message': 'Lesson uploaded', 'data': body ?? {}};
    }
    // Create announcement (tutor)
    if (endpoint == 'tutor/announcements') {
      return {'message': 'Announcement sent', 'data': body ?? {}};
    }
    // Public application
    if (endpoint == 'public/apply') {
      return {'message': 'Application received', 'data': body ?? {}};
    }
    // Tutor clock-in
    if (endpoint == 'tutor/clock-in') {
      return {'message': 'Clock-in recorded', 'data': body ?? {}};
    }
    // Tutor lesson outline
    if (endpoint == 'tutor/lesson-outline') {
      return {'message': 'Lesson outline saved', 'data': body ?? {}};
    }
    return {'message': 'OK (offline mode)', 'data': body ?? {}};
  }

  // ─── Convenience endpoints ────────────────────────────────────────────────

  // Courses
  static Future<Map<String, dynamic>> getCourses() =>
      get('public/courses');
  static Future<Map<String, dynamic>> getCourse(int id) => get('courses/$id');

  // Student dashboard
  static Future<Map<String, dynamic>> getStudentDashboard() =>
      get('student/dashboard');
  static Future<Map<String, dynamic>> getStudentCourses() =>
      get('student/courses');
  static Future<Map<String, dynamic>> getStudentLessons(int courseId) =>
      get('student/lessons', params: {'course_id': courseId.toString()});
  static Future<Map<String, dynamic>> getStudentAssignments() =>
      get('student/assignments');
  static Future<Map<String, dynamic>> getStudentResults() =>
      get('student/results');
  static Future<Map<String, dynamic>> getStudentCertificates() =>
      get('student/certificates');
  static Future<Map<String, dynamic>> getStudentNotifications() =>
      get('student/notifications');
  static Future<Map<String, dynamic>> markNotificationRead(int id) =>
      put('student/notifications/$id', {'is_read': 1});
  static Future<Map<String, dynamic>> getStudentProfile() =>
      get('student/profile');
  static Future<Map<String, dynamic>> updateStudentProfile(
          Map<String, dynamic> data) =>
      put('student/profile', data);
  static Future<Map<String, dynamic>> changeStudentPassword(
          Map<String, dynamic> data) =>
      post('student/change-password', data);

  // Tutor
  static Future<Map<String, dynamic>> getTutorDashboard() =>
      get('tutor/dashboard');
  static Future<Map<String, dynamic>> getTutorCourses() =>
      get('tutor/courses');
  static Future<Map<String, dynamic>> getTutorLessons(int courseId) =>
      get('tutor/lessons', params: {'course_id': courseId.toString()});
  static Future<Map<String, dynamic>> getTutorAssignments() =>
      get('tutor/assignments');
  static Future<Map<String, dynamic>> getTutorStudents() =>
      get('tutor/students');
  static Future<Map<String, dynamic>> getTutorSubmissions(int assignmentId) =>
      get('tutor/submissions',
          params: {'assignment_id': assignmentId.toString()});
  static Future<Map<String, dynamic>> gradeSubmission(
          int submissionId, Map<String, dynamic> data) =>
      put('tutor/submissions/$submissionId', data);
  static Future<Map<String, dynamic>> createAnnouncement(
          Map<String, dynamic> data) =>
      post('tutor/announcements', data);

  // Public
  static Future<Map<String, dynamic>> getPublicCourses() =>
      get('public/courses');
  static Future<Map<String, dynamic>> submitApplication(
          Map<String, dynamic> data) =>
      post('public/apply', data);
  static Future<Map<String, dynamic>> getSettings(List<String> keys) =>
      get('settings', params: {'keys': keys.join(',')});
}
