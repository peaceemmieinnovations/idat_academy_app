import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Change this to your server's IP/domain
  static const String baseUrl = 'http://192.168.18.20/idat-academy-portal/api';
  static const String apiKey = 'idat_live_k8x2m9p4q7w1e5r3t6y0u';

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

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> studentLogin(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/student/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> tutorLogin(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/tutor/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<void> saveToken(String token, String role) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  static Future<String?> getToken() => _storage.read(key: 'auth_token');
  static Future<String?> getRole() => _storage.read(key: 'user_role');

  // ─── Generic GET ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse('$baseUrl/$endpoint');
      if (params != null) uri = uri.replace(queryParameters: params);
      final headers = await _authHeaders();
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint,
      Map<String, dynamic> body) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .put(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── File upload ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(
      String endpoint, File file, Map<String, String> fields) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));
      request.headers['X-API-Key'] = apiKey;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files
          .add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Convenience endpoints ────────────────────────────────────────────────

  // Courses
  static Future<Map<String, dynamic>> getCourses() => get('courses');
  static Future<Map<String, dynamic>> getCourse(int id) =>
      get('courses/$id');

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
