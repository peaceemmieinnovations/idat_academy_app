import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'mock_data.dart';

/// Persists staff attendance clock-in session.
class StaffAttendanceSession {
  static const _storage = FlutterSecureStorage();
  static const _key = 'staff_attendance';

  static Future<void> save(DateTime clockInTime, String plan) async {
    await _storage.write(key: _key, value: jsonEncode({
      'clock_in': clockInTime.toIso8601String(),
      'plan': plan,
      'report': '',
    }));
  }

  static Future<Map<String, dynamic>?> restore() async {
    final data = await _storage.read(key: _key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

class ApiService {
  /// This build is connected to production.  Requests must never be replaced
  /// with sample data: doing so can make an unavailable server look successful.
  static const bool demoMode = false;

  /// Live API base URL
  static const String baseUrl = 'https://idat.ng/api';
  static const String fileBaseUrl = 'https://idat.ng';
  static const String apiKey = 'idat_live_k8x2m9p4q7w1e5r3t6y0u';

  static const _storage = FlutterSecureStorage();

  static int? _studentId;
  static int? _tutorId;
  static int? _staffId;

  static int? get studentId => _studentId;
  static int? get tutorId => _tutorId;
  static int? get staffId => _staffId;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  static Future<Map<String, String>> _authHeaders() async {
    await _restoreUserIds();
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _restoreUserIds() async {
    _studentId ??= int.tryParse(await _storage.read(key: 'student_id') ?? '');
    _tutorId ??= int.tryParse(await _storage.read(key: 'tutor_id') ?? '');
    _staffId ??= int.tryParse(await _storage.read(key: 'staff_id') ?? '');
  }

  static Future<Map<String, dynamic>> _request(
    Future<Map<String, dynamic>> Function() apiCall, {
    required Map<String, dynamic> Function() mockFallback,
  }) async {
    try {
      if (demoMode) return mockFallback();
      return await apiCall();
    } catch (e) {
      return {'error': 'Unable to reach the IDAT Academy server. Please check your connection and try again.'};
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return {
        'error': response.statusCode == 401
            ? 'Sign-in was not accepted. Check your email and password.'
            : response.statusCode == 403
                ? 'You do not have permission to perform this action.'
                : 'The IDAT Academy server did not return a response.',
        'status': response.statusCode,
      };
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      return {
        'error': 'The IDAT Academy server returned an invalid response.',
        'status': response.statusCode,
      };
    }
    if (decoded is! Map<String, dynamic>) {
      return {
        'error': 'The IDAT Academy server returned an unexpected response.',
        'status': response.statusCode,
      };
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return {
        ...decoded,
        'error': decoded['error'] ?? decoded['message'] ?? 'Request failed.',
        'status': response.statusCode,
      };
    }
    return decoded;
  }

  // ─── Endpoint rewriting ─────────────────────────────────────────────────────

  /// Maps old endpoint paths used by screens to new API paths.
  static String _rewrite(String endpoint) {
    // Student endpoints
    if (endpoint == 'student/dashboard') return 'stats';
    if (endpoint == 'student/courses') return 'enrollments';
    if (endpoint == 'student/assignments') return 'assignments';
    if (endpoint == 'student/results') return 'assignments';
    if (endpoint == 'student/certificates') return 'certificates';
    if (endpoint == 'student/notifications') return 'notifications';
    if (endpoint == 'student/profile') return _studentId != null ? 'students/$_studentId' : 'students';
    if (endpoint == 'student/change-password') return endpoint; // not in new API
    if (endpoint == 'student/register-course') return 'enrollments';
    if (endpoint.startsWith('student/notifications/')) {
      return endpoint.replaceFirst('student/', '');
    }
    if (endpoint.startsWith('student/assignments/')) {
      // student/assignments/{id}/submit → submissions
      if (endpoint.endsWith('/submit')) {
        return 'submissions';
      }
    }
    if (endpoint.startsWith('student/lessons')) {
      return endpoint.replaceFirst('student/', '');
    }

    // Tutor endpoints
    if (endpoint == 'tutor/dashboard') return 'stats';
    if (endpoint == 'tutor/courses') return 'courses';
    if (endpoint == 'tutor/assignments') return 'assignments';
    if (endpoint == 'tutor/students') return 'students';
    if (endpoint == 'tutor/profile') return _tutorId != null ? 'tutors/$_tutorId' : 'tutors';
    if (endpoint == 'tutor/announcements') return 'announcements';
    if (endpoint == 'tutor/clock-in') return 'attendance/scan';
    if (endpoint == 'tutor/clock-out') return 'attendance/scan';
    if (endpoint == 'tutor/lesson-outline') return 'course_outlines';
    if (endpoint.startsWith('tutor/submissions')) {
      return endpoint.replaceFirst('tutor/', '');
    }
    if (endpoint.startsWith('tutor/lessons')) {
      return endpoint.replaceFirst('tutor/', '');
    }
    if (endpoint.startsWith('tutor/notifications/')) {
      return endpoint.replaceFirst('tutor/', '');
    }

    // Staff attendance
    if (endpoint == 'staff/attendance/clock-in') return 'attendance/scan';
    if (endpoint == 'staff/attendance/clock-out') return 'attendance/scan';
    if (endpoint == 'staff/attendance/plan') return endpoint; // no equivalent
    if (endpoint == 'staff/attendance/report') return endpoint; // no equivalent

    // Public
    if (endpoint == 'public/courses') return 'courses';
    if (endpoint == 'public/apply') return 'applications';

    return endpoint;
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// Unified login for both student and tutor.
  /// Returns a normalized response matching the old format so auth_provider
  /// does not need changes: {token, student} or {token, tutor}.
  static Future<Map<String, dynamic>> login(
      String email, String password, String portal) async {
    return _request(() async {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'portal': portal,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final raw = _decodeResponse(res);

      // Normalize new API format to old format
      if (raw['access_token'] != null) {
        final user = raw['user'] ?? {};
        final accountType = raw['account_type'] ?? '';
        final id = user['id'];
        // account_type = "student" or account_type = "staff" with role = "tutor"
        if (accountType == 'student') {
          if (id != null) _studentId = id is int ? id : int.tryParse('$id');
          return {
            'token': raw['access_token'],
            'student': user,
          };
        }
        // Preserve the backend's staff role. All staff use the same workspace
        // in this app, but a generic staff account must not be labelled Tutor.
        final role = '${raw['role'] ?? ''}'.toLowerCase();
        final appRole = role == 'tutor' ? 'tutor' : 'staff';
        if (id != null) {
          _tutorId = id is int ? id : int.tryParse('$id');
          _staffId = _tutorId;
        }
        return {
          'token': raw['access_token'],
          'tutor': user,
          'app_role': appRole,
          'staff_role': role.isEmpty ? 'staff' : role,
        };
      }
      return raw;
    }, mockFallback: () => {'error': 'Demo mode is not available in this build.'});
  }

  static Future<Map<String, dynamic>> studentLogin(
      String email, String password) async {
    return login(email, password, 'student');
  }

  static Future<Map<String, dynamic>> tutorLogin(
      String email, String password) async {
    return login(email, password, 'tutor');
  }

  static Future<void> saveToken(String token, String role,
      {String? staffRole}) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_role', value: role);
    if (staffRole != null) {
      await _storage.write(key: 'staff_role', value: staffRole);
    } else {
      await _storage.delete(key: 'staff_role');
    }
    if (_studentId != null) {
      await _storage.write(key: 'student_id', value: _studentId.toString());
    }
    if (_tutorId != null) {
      await _storage.write(key: 'tutor_id', value: _tutorId.toString());
    }
    if (_staffId != null) {
      await _storage.write(key: 'staff_id', value: _staffId.toString());
    }
  }

  static Future<void> clearSession() async {
    _studentId = null;
    _tutorId = null;
    _staffId = null;
    await _storage.deleteAll();
  }

  static Future<String?> getToken() => _storage.read(key: 'auth_token');
  static Future<String?> getRole() => _storage.read(key: 'user_role');
  static Future<String?> getStaffRole() => _storage.read(key: 'staff_role');

  // ─── Generic GET/POST/PUT ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? params}) async {
    final rewritten = _rewrite(endpoint);
    return _request(() async {
      var uri = Uri.parse('$baseUrl/$rewritten');
      if (params != null) uri = uri.replace(queryParameters: params);
      final headers = await _authHeaders();
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      return _decodeResponse(res);
    }, mockFallback: () => _mockGet(rewritten, params));
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final rewritten = _rewrite(endpoint);
    final requestBody = <String, dynamic>{...body};
    final submissionId = _assignmentIdFromSubmissionEndpoint(endpoint);
    if (rewritten == 'submissions' && submissionId != null) {
      requestBody.putIfAbsent('assignment_id', () => submissionId);
      if (_studentId != null) {
        requestBody.putIfAbsent('student_id', () => _studentId);
      }
    }
    return _request(() async {
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$baseUrl/$rewritten'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      return _decodeResponse(res);
    }, mockFallback: () => _mockPost(rewritten, requestBody));
  }

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final rewritten = _rewrite(endpoint);
    return _request(() async {
      final headers = await _authHeaders();
      final res = await http
          .put(
            Uri.parse('$baseUrl/$rewritten'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _decodeResponse(res);
    }, mockFallback: () => _mockPost(rewritten, body));
  }

  /// AI calls go through the academy backend; provider keys never belong in
  /// the mobile application.
  static Future<Map<String, dynamic>> askLessonAi(int lessonId, String question) =>
      post('ai/lessons/$lessonId/chat', {'question': question});

  static Future<Map<String, dynamic>> reviewAssignmentAi(int assignmentId, String draft) =>
      post('ai/assignments/$assignmentId/review', {'draft': draft});

  static Future<Map<String, dynamic>> getLessonAiSummary(int lessonId) =>
      get('lessons/$lessonId/ai-summary');

  static Future<Map<String, dynamic>> getLessonAiQuiz(int lessonId, {int count = 5}) =>
      get('lessons/$lessonId/ai-quiz', params: {'count': '$count'});

  static Future<Map<String, dynamic>> getCareerPathAi() => get('ai/career-path');

  // ─── File upload ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(
      String endpoint, File file, Map<String, String> fields) async {
    final rewritten = _rewrite(endpoint);
    final requestFields = <String, String>{...fields};
    final submissionId = _assignmentIdFromSubmissionEndpoint(endpoint);
    if (rewritten == 'submissions' && submissionId != null) {
      requestFields.putIfAbsent('assignment_id', () => submissionId.toString());
      if (_studentId != null) {
        requestFields.putIfAbsent('student_id', () => _studentId.toString());
      }
    }
    return _request(() async {
      final token = await _storage.read(key: 'auth_token');
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$rewritten'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(requestFields);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _decodeResponse(res);
    }, mockFallback: () => {'message': 'File saved (offline mode)'});
  }

  static int? _assignmentIdFromSubmissionEndpoint(String endpoint) {
    final match = RegExp(r'^student/assignments/(\d+)/submit$').firstMatch(endpoint);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  // ─── Response normalizers ─────────────────────────────────────────────────

  // ─── Convenience endpoints ────────────────────────────────────────────────

  // Courses
  static Future<Map<String, dynamic>> getCourses() => get('courses');
  static Future<Map<String, dynamic>> getPublicCourses() => get('courses');
  static Future<Map<String, dynamic>> getCourse(int id) => get('courses/$id');

  // Student dashboard — uses student-accessible endpoints (stats is admin-only)
  static Future<Map<String, dynamic>> getStudentDashboard() async {
    final res = await _request(
      () async {
        final headers = await _authHeaders();
        // Fetch enrollments to get course list + progress
        final enrollRes = await http
            .get(Uri.parse('$baseUrl/enrollments'), headers: headers)
            .timeout(const Duration(seconds: 30));
        final enrollData = _decodeResponse(enrollRes);
        if (enrollData['error'] != null) return enrollData;
        final enrollments = (enrollData['data'] as List?) ?? [];

        // Fetch unread notification count
        int unreadNotifs = 0;
        try {
          final notifRes = await http
              .get(Uri.parse('$baseUrl/notifications'), headers: headers)
              .timeout(const Duration(seconds: 15));
          final notifData = _decodeResponse(notifRes);
          final notifs = (notifData['data'] as List?) ?? [];
          unreadNotifs = notifs
              .where((n) => n['is_read'] == false || n['is_read'] == 0)
              .length;
        } catch (_) {}

        // Fetch certificates count
        int certCount = 0;
        try {
          final certRes = await http
              .get(Uri.parse('$baseUrl/certificates'), headers: headers)
              .timeout(const Duration(seconds: 15));
          final certData = _decodeResponse(certRes);
          certCount = (certData['data'] as List?)?.length ?? 0;
        } catch (_) {}

        return {
          'data': {
            'enrolled_courses': enrollments.length,
            'completed_courses': enrollments
                .where((e) => (e['status'] ?? '') == 'completed')
                .length,
            'pending_assignments': 0,
            'certificates': certCount,
            'unread_notifications': unreadNotifs,
            'recent_courses': enrollments.map((e) {
              final course = e['course'] ?? e;
              return {
                'id': course['id'] ?? e['course_id'] ?? 0,
                'title': course['title'] ?? '',
                'slug': course['slug'] ?? '',
                'description': course['description'],
                'image': course['image'],
                'icon': course['icon'],
                'duration': course['duration'],
                'learning_mode':
                    course['learning_mode'] ?? e['learning_mode'] ?? 'hybrid',
                'requirements': course['requirements'],
                'category': course['category'] ?? 'professional',
                'price': course['price']?.toString() ?? '0',
                'status': course['status'] ?? 'active',
                'progress': e['progress']?.toString(),
              };
            }).toList(),
          },
        };
      },
      mockFallback: MockData.studentDashboard,
    );
    return res;
  }

  /// Returns every available course and adds enrollment/progress data to the
  /// courses belonging to the signed-in student. This gives mobile screens one
  /// stable list for both “My courses” and “Available courses”.
  static Future<Map<String, dynamic>> getStudentCourses() async {
    return _request(() async {
      final headers = await _authHeaders();
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/courses?all=true'), headers: headers)
            .timeout(const Duration(seconds: 30)),
        http.get(Uri.parse('$baseUrl/enrollments?all=true'), headers: headers)
            .timeout(const Duration(seconds: 30)),
      ]);
      final coursesResponse = _decodeResponse(responses[0]);
      if (coursesResponse['error'] != null) return coursesResponse;
      final enrollmentsResponse = _decodeResponse(responses[1]);
      if (enrollmentsResponse['error'] != null) return enrollmentsResponse;

      final enrollments = (enrollmentsResponse['data'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final enrollmentByCourse = <String, Map<String, dynamic>>{};
      for (final enrollment in enrollments) {
        final course = enrollment['course'];
        final id = enrollment['course_id'] ??
            (course is Map ? course['id'] : null);
        if (id != null) enrollmentByCourse['$id'] = enrollment;
      }
      final courses = (coursesResponse['data'] as List? ?? []).map((item) {
        final course = Map<String, dynamic>.from(item as Map);
        final enrollment = enrollmentByCourse['${course['id']}'];
        if (enrollment == null) return course;
        return {
          ...course,
          'progress': enrollment['progress'],
          'enrollment_status': enrollment['status'],
        };
      }).toList();
      return {'data': courses, 'pagination': coursesResponse['pagination']};
    }, mockFallback: MockData.studentCourses);
  }
  static Future<Map<String, dynamic>> getStudentLessons(int courseId) =>
      get('lessons', params: {'course_id': courseId.toString()});
  static Future<Map<String, dynamic>> getStudentAssignments() async {
    return _request(
      () async {
        final headers = await _authHeaders();
        final assignRes = await http
            .get(Uri.parse('$baseUrl/assignments'), headers: headers)
            .timeout(const Duration(seconds: 30));
        final assignData = _decodeResponse(assignRes);
        if (assignData['error'] != null) return assignData;
        final assignments = (assignData['data'] as List?) ?? [];

        // Merge submission status into assignments
        try {
          final subRes = await http
              .get(Uri.parse('$baseUrl/submissions'), headers: headers)
              .timeout(const Duration(seconds: 15));
          final subData = _decodeResponse(subRes);
          final submissions = (subData['data'] as List?) ?? [];
          final subByAssign = <int, Map<String, dynamic>>{};
          for (final s in submissions) {
            final aid = s['assignment_id'];
            if (aid != null) {
              subByAssign[aid is int ? aid : int.tryParse('$aid') ?? 0] = s;
            }
          }
          final merged = assignments.map((a) {
            final aId = a['id'] is int ? a['id'] : int.tryParse('${a['id']}') ?? 0;
            final sub = subByAssign[aId];
            if (sub != null) {
              return {
                ...a,
                'submitted': true,
                'score': sub['score'],
                'feedback': sub['feedback'],
                'submitted_at': sub['submitted_at'],
              };
            }
            return a;
          }).toList();
          return {'data': merged};
        } catch (_) {
          return assignData;
        }
      },
      mockFallback: MockData.studentAssignments,
    );
  }

  static Future<Map<String, dynamic>> getStudentResults() async {
    return _request(
      () async {
        final headers = await _authHeaders();
        final subRes = await http
            .get(Uri.parse('$baseUrl/submissions?graded=true'),
                headers: headers)
            .timeout(const Duration(seconds: 30));
        final subData = _decodeResponse(subRes);
        if (subData['error'] != null) return subData;
        final submissions = (subData['data'] as List?) ?? [];

        // Fetch assignment titles for each submission
        final assignRes = await http
            .get(Uri.parse('$baseUrl/assignments'), headers: headers)
            .timeout(const Duration(seconds: 15));
        final assignData = _decodeResponse(assignRes);
        if (assignData['error'] != null) return assignData;
        final assignments = (assignData['data'] as List?) ?? [];
        final assignById = <int, Map<String, dynamic>>{};
        for (final a in assignments) {
          final aId = a['id'] is int ? a['id'] : int.tryParse('${a['id']}') ?? 0;
          assignById[aId] = a;
        }

        final graded = submissions
            .where((s) => s['score'] != null)
            .map((s) {
              final aId = s['assignment_id'] is int
                  ? s['assignment_id']
                  : int.tryParse('${s['assignment_id']}') ?? 0;
              final assign = assignById[aId] ?? {};
              return {
                'id': s['assignment_id'],
                'course_id': assign['course_id'],
                'title': assign['title'] ?? '',
                'max_score': assign['max_score'] ?? '100',
                'due_date': assign['due_date'],
                'course_title': assign['course_title'] ?? '',
                'score': s['score'],
                'feedback': s['feedback'],
                'submitted': true,
                'submitted_at': s['submitted_at'],
              };
            })
            .toList();
        return {'data': graded};
      },
      mockFallback: MockData.studentResults,
    );
  }
  static Future<Map<String, dynamic>> getStudentCertificates() =>
      get('certificates');
  static Future<Map<String, dynamic>> getStudentNotifications() =>
      get('notifications');
  static Future<Map<String, dynamic>> markNotificationRead(int id) =>
      put('notifications/$id', {'is_read': 1});
  static Future<Map<String, dynamic>> getStudentProfile() async {
    await _restoreUserIds();
    final res = await _request(
      () async {
        final endpoint = _studentId != null ? 'students/$_studentId' : 'students';
        final headers = await _authHeaders();
        final httpRes = await http
            .get(Uri.parse('$baseUrl/$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 30));
        final raw = _decodeResponse(httpRes);
        // Normalize: wrap raw response in {data: ...} if not already paginated
        if (raw is Map && !raw.containsKey('data') && raw['error'] == null) {
          return {'data': raw};
        }
        return raw;
      },
      mockFallback: MockData.studentProfile,
    );
    return res;
  }
  static Future<Map<String, dynamic>> updateStudentProfile(
      Map<String, dynamic> data) async {
    await _restoreUserIds();
    if (_studentId == null) {
      return {
        'error': 'Your student profile could not be identified. Please sign in again.'
      };
    }
    return put('students/$_studentId', data);
  }
  static Future<Map<String, dynamic>> changeStudentPassword(
          Map<String, dynamic> data) =>
      post('change-password', data);

  // Device tokens
  static Future<Map<String, dynamic>> registerDeviceToken(String token) =>
      post('notifications/devices',
          {'device_token': token, 'platform': 'android'});
  static Future<Map<String, dynamic>> unregisterDeviceToken(String token) =>
      post('notifications/devices/remove', {'device_token': token});

  static Future<Map<String, dynamic>> registerCourse(int courseId) =>
      post('enrollments', {'course_id': courseId});

  // Tutor dashboard — uses tutor profile (stats is admin-only)
  static Future<Map<String, dynamic>> getTutorDashboard() async {
    await _restoreUserIds();
    final res = await _request(
      () async {
        final headers = await _authHeaders();
        final endpoint =
            _tutorId != null ? 'tutors/$_tutorId' : 'tutors';
        final httpRes = await http
            .get(Uri.parse('$baseUrl/$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 30));
        final raw = _decodeResponse(httpRes);
        if (raw['error'] != null) return raw;
        final tutorData = raw['data'] ?? raw;
        final courses = (tutorData['courses'] as List?) ?? [];
        return {
          'data': {
            'total_students': tutorData['total_students'] ??
                tutorData['students_count'] ?? 0,
            'total_courses': courses.length,
            'pending_submissions': 0,
            'total_lessons': tutorData['total_lessons'] ??
                tutorData['lessons_count'] ?? 0,
            'courses': courses,
          },
        };
      },
      mockFallback: MockData.tutorDashboard,
    );
    return res;
  }

  static Future<Map<String, dynamic>> getTutorCourses() async {
    await _restoreUserIds();
    return get('courses',
        params: _tutorId == null ? null : {'tutor_id': _tutorId.toString()});
  }
  static Future<Map<String, dynamic>> getTutorLessons(int courseId) async {
    await _restoreUserIds();
    return get('lessons', params: {
      'course_id': courseId.toString(),
      if (_tutorId != null) 'tutor_id': _tutorId.toString(),
    });
  }
  static Future<Map<String, dynamic>> getTutorAssignments() async {
    await _restoreUserIds();
    return get('assignments',
        params: _tutorId == null ? null : {'tutor_id': _tutorId.toString()});
  }
  static Future<Map<String, dynamic>> getTutorStudents() => get('students');
  static Future<Map<String, dynamic>> getTutorSubmissions(
          int assignmentId) =>
      get('submissions',
          params: {'assignment_id': assignmentId.toString()});
  static Future<Map<String, dynamic>> getTutorProfile() async {
    await _restoreUserIds();
    final res = await _request(
      () async {
        final endpoint =
            _tutorId != null ? 'tutors/$_tutorId' : 'tutors';
        final headers = await _authHeaders();
        final httpRes = await http
            .get(Uri.parse('$baseUrl/$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 30));
        final raw = _decodeResponse(httpRes);
        if (raw is Map && !raw.containsKey('data') && raw['error'] == null) {
          return {'data': raw};
        }
        return raw;
      },
      mockFallback: MockData.tutorProfile,
    );
    return res;
  }

  static Future<Map<String, dynamic>> gradeSubmission(
          int submissionId, Map<String, dynamic> data) =>
      put('submissions/$submissionId', data);
  static Future<Map<String, dynamic>> createAnnouncement(
          Map<String, dynamic> data) =>
      post('announcements', data);
  static Future<Map<String, dynamic>> updateTutorProfile(
      Map<String, dynamic> data) async {
    await _restoreUserIds();
    if (_staffId == null) {
      return {
        'error': 'Your staff profile could not be identified. Please sign in again.'
      };
    }
    return put('staff/$_staffId', data);
  }

  // Public
  static Future<Map<String, dynamic>> submitApplication(
          Map<String, dynamic> data) =>
      post('applications', data);
  static Future<Map<String, dynamic>> getSettings(List<String> keys) =>
      get('settings', params: {'keys': keys.join(',')});

  // ─── Mock router for GET ─────────────────────────────────────────────────

  static Map<String, dynamic> _mockGet(
      String endpoint, Map<String, String>? params) {
    switch (endpoint) {
      case 'stats':
        return MockData.studentDashboard();
      case 'courses':
      case 'enrollments':
        return MockData.studentCourses();
      case 'students':
        return MockData.tutorStudents();
      case 'assignments':
        return MockData.studentAssignments();
      case 'submissions':
        return MockData.tutorSubmissions(
            int.tryParse(params?['assignment_id'] ?? '') ?? 1);
      case 'certificates':
        return MockData.studentCertificates();
      case 'notifications':
        return MockData.studentNotifications();
      default:
        if (endpoint.startsWith('students/') || endpoint == 'students') {
          return MockData.studentProfile();
        }
        if (endpoint.startsWith('tutors/') || endpoint == 'tutors') {
          return MockData.tutorProfile();
        }
        if (endpoint == 'lessons' && params != null) {
          final courseId = int.tryParse(params['course_id'] ?? '') ?? 0;
          return MockData.lessons(courseId);
        }
        if (endpoint.startsWith('notifications/')) {
          return {'message': 'Notification marked as read'};
        }
        if (endpoint.startsWith('submissions/')) {
          return {'message': 'Grade saved', 'data': {}};
        }
        return {'data': []};
    }
  }

  // ─── Mock router for POST/PUT ────────────────────────────────────────────

  static Map<String, dynamic> _mockPost(
      String endpoint, Map<String, dynamic>? body) {
    if (endpoint.startsWith('notifications/')) {
      return {'message': 'Notification marked as read'};
    }
    if (endpoint == 'student/change-password') {
      return {'message': 'Password changed successfully'};
    }
    if (endpoint.startsWith('students/') || endpoint == 'students') {
      return {'message': 'Profile updated', 'data': body ?? {}};
    }
    if (endpoint.startsWith('tutors/') || endpoint == 'tutors') {
      return {
        'message': 'Profile updated',
        'data': {...MockData.tutorProfile()['data'], ...?body},
      };
    }
    if (endpoint == 'submissions') {
      return {'message': 'Assignment submitted successfully'};
    }
    if (endpoint == 'assignments') {
      return {'message': 'Assignment created', 'data': body ?? {}};
    }
    if (endpoint.startsWith('submissions/')) {
      return {'message': 'Grade saved', 'data': body ?? {}};
    }
    if (endpoint == 'lessons') {
      return {'message': 'Lesson uploaded', 'data': body ?? {}};
    }
    if (endpoint == 'announcements') {
      return {'message': 'Announcement sent', 'data': body ?? {}};
    }
    if (endpoint == 'attendance/scan') {
      return {'message': 'Attendance recorded', 'data': body ?? {}};
    }
    if (endpoint == 'course_outlines') {
      return {'message': 'Lesson outline saved', 'data': body ?? {}};
    }
    if (endpoint == 'enrollments') {
      final courseId = body?['course_id'];
      if (courseId != null) MockData.addRegistration(courseId as int);
      return {'message': 'Enrolled successfully', 'data': body ?? {}};
    }
    if (endpoint == 'applications') {
      return {'message': 'Application received', 'data': body ?? {}};
    }
    if (endpoint == 'settings') {
      return {'message': 'Settings saved', 'data': body ?? {}};
    }
    return {'message': 'OK (offline mode)', 'data': body ?? {}};
  }
}
