// ─── User models ─────────────────────────────────────────────────────────────

class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photo;
  final String status;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photo,
    required this.status,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        firstName: j['first_name'] ?? '',
        lastName: j['last_name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'],
        photo: j['photo'],
        status: j['status'] ?? 'active',
      );
}

class Tutor {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photo;
  final String? bio;

  Tutor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photo,
    this.bio,
  });

  String get fullName => '$firstName $lastName';

  factory Tutor.fromJson(Map<String, dynamic> j) => Tutor(
        id: j['id'],
        firstName: j['first_name'] ?? '',
        lastName: j['last_name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'],
        photo: j['photo'],
        bio: j['bio'],
      );
}

// ─── Course ──────────────────────────────────────────────────────────────────

class Course {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? image;
  final String? icon;
  final String? duration;
  final String learningMode;
  final String? requirements;
  final String category;
  final double price;
  final String status;
  final double? progress; // for enrolled courses

  Course({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.image,
    this.icon,
    this.duration,
    required this.learningMode,
    this.requirements,
    required this.category,
    required this.price,
    required this.status,
    this.progress,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        title: j['title'] ?? '',
        slug: j['slug'] ?? '',
        description: j['description'],
        image: j['image'],
        icon: j['icon'],
        duration: j['duration'],
        learningMode: j['learning_mode'] ?? 'hybrid',
        requirements: j['requirements'],
        category: j['category'] ?? 'professional',
        price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
        status: j['status'] ?? 'active',
        progress: double.tryParse(j['progress']?.toString() ?? ''),
      );
}

// ─── Lesson ──────────────────────────────────────────────────────────────────

class Lesson {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String? filePath;
  final String fileType;
  final String createdAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.filePath,
    required this.fileType,
    required this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'],
        courseId: j['course_id'],
        title: j['title'] ?? '',
        description: j['description'],
        filePath: j['download_url'] ?? j['file_path'] ?? j['url'],
        fileType: j['file_type'] ?? 'pdf',
        createdAt: j['created_at'] ?? '',
      );

  String get fileTypeLabel {
    switch (fileType) {
      case 'pdf': return 'PDF';
      case 'ppt': return 'Slides';
      case 'notes': return 'Notes';
      default: return 'File';
    }
  }
}

// ─── Assignment ──────────────────────────────────────────────────────────────

class Assignment {
  final int id;
  final int courseId;
  final String title;
  final String? instructions;
  final String acceptedFileTypes;
  final double maxScore;
  final String? dueDate;
  final String? courseTitle;
  // Submission info (when fetched for a student)
  final double? score;
  final String? feedback;
  final bool? submitted;
  final String? submittedAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    this.instructions,
    required this.acceptedFileTypes,
    required this.maxScore,
    this.dueDate,
    this.courseTitle,
    this.score,
    this.feedback,
    this.submitted,
    this.submittedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        id: j['id'],
        courseId: j['course_id'],
        title: j['title'] ?? '',
        instructions: j['instructions'],
        acceptedFileTypes: j['accepted_file_types'] ?? 'pdf,doc,docx,zip',
        maxScore: double.tryParse(j['max_score']?.toString() ?? '100') ?? 100,
        dueDate: j['due_date'],
        courseTitle: j['course_title'],
        score: double.tryParse(j['score']?.toString() ?? ''),
        feedback: j['feedback'],
        submitted: j['submitted'] == true || j['submitted'] == 1,
        submittedAt: j['submitted_at'],
      );
}

// ─── Certificate ─────────────────────────────────────────────────────────────

class Certificate {
  final int id;
  final String courseTitle;
  final String certificateNumber;
  final String? filePath;
  final String issueDate;

  Certificate({
    required this.id,
    required this.courseTitle,
    required this.certificateNumber,
    this.filePath,
    required this.issueDate,
  });

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
        id: j['id'],
        courseTitle: j['course_title'] ?? '',
        certificateNumber: j['certificate_number'] ?? '',
        filePath: j['download_url'] ?? j['file_path'] ?? j['url'],
        issueDate: j['issue_date'] ?? '',
      );
}

// ─── Notification ────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? message;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        type: j['type'] ?? 'general',
        title: j['title'] ?? '',
        message: j['message'],
        isRead: j['is_read'] == 1 || j['is_read'] == true,
        createdAt: j['created_at'] ?? '',
      );
}

// ─── Dashboard Stats ─────────────────────────────────────────────────────────

class StudentDashboard {
  final int enrolledCourses;
  final int completedCourses;
  final int pendingAssignments;
  final int certificates;
  final int unreadNotifications;
  final List<Course> recentCourses;

  StudentDashboard({
    required this.enrolledCourses,
    required this.completedCourses,
    required this.pendingAssignments,
    required this.certificates,
    required this.unreadNotifications,
    required this.recentCourses,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> j) {
    final data = j['data'] ?? j;
    return StudentDashboard(
      enrolledCourses: data['enrolled_courses'] ?? 0,
      completedCourses: data['completed_courses'] ?? 0,
      pendingAssignments: data['pending_assignments'] ?? 0,
      certificates: data['certificates'] ?? 0,
      unreadNotifications: data['unread_notifications'] ?? 0,
      recentCourses: (data['recent_courses'] as List? ?? [])
          .map((c) => Course.fromJson(c))
          .toList(),
    );
  }
}

class TutorDashboard {
  final int totalStudents;
  final int totalCourses;
  final int pendingSubmissions;
  final int totalLessons;
  final List<Course> courses;

  TutorDashboard({
    required this.totalStudents,
    required this.totalCourses,
    required this.pendingSubmissions,
    required this.totalLessons,
    required this.courses,
  });

  factory TutorDashboard.fromJson(Map<String, dynamic> j) {
    final data = j['data'] ?? j;
    return TutorDashboard(
      totalStudents: data['total_students'] ?? 0,
      totalCourses: data['total_courses'] ?? 0,
      pendingSubmissions: data['pending_submissions'] ?? 0,
      totalLessons: data['total_lessons'] ?? 0,
      courses: (data['courses'] as List? ?? [])
          .map((c) => Course.fromJson(c))
          .toList(),
    );
  }
}

// ─── Submission ──────────────────────────────────────────────────────────────

class Submission {
  final int id;
  final int assignmentId;
  final String studentName;
  final String? filePath;
  final String? typedResponse;
  final String submittedAt;
  final double? score;
  final String? feedback;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentName,
    this.filePath,
    this.typedResponse,
    required this.submittedAt,
    this.score,
    this.feedback,
  });

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
        id: j['id'],
        assignmentId: j['assignment_id'],
        studentName: j['student_name'] ?? 'Unknown',
        filePath: j['file_path'],
        typedResponse: j['typed_response'],
        submittedAt: j['submitted_at'] ?? '',
        score: double.tryParse(j['score']?.toString() ?? ''),
        feedback: j['feedback'],
      );
}
