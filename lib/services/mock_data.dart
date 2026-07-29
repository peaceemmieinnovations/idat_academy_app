/// Provides realistic mock data for offline/demo mode.
/// Used when the backend API is unreachable.
class MockData {
  // ─── Demo credentials ─────────────────────────────────────────────────────
  static const String studentEmail = 'student@idat.com';
  static const String tutorEmail = 'tutor@idat.com';
  static const String password = 'idat123';

  // ─── Student login ────────────────────────────────────────────────────────
  static Map<String, dynamic> studentLogin() => {
        'token': 'mock_token_student_demo_2024',
        'student': {
          'id': 101,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': studentEmail,
          'phone': '+2348012345678',
          'photo': null,
          'status': 'active',
        },
      };

  // ─── Tutor login ──────────────────────────────────────────────────────────
  static Map<String, dynamic> tutorLogin() => {
        'token': 'mock_token_tutor_demo_2024',
        'tutor': {
          'id': 201,
          'first_name': 'Sarah',
          'last_name': 'Johnson',
          'email': tutorEmail,
          'phone': '+2348098765432',
          'photo': null,
          'bio': 'Senior instructor with 8+ years of experience in software development and cybersecurity.',
        },
      };

  // ─── Student profile ──────────────────────────────────────────────────────
  static Map<String, dynamic> studentProfile() => {
        'data': {
          'id': 101,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': studentEmail,
          'phone': '+2348012345678',
          'address': '12, Awolowo Road, Ikoyi, Lagos',
          'photo': null,
          'status': 'active',
        },
      };

  // ─── Student dashboard ────────────────────────────────────────────────────
  static Map<String, dynamic> studentDashboard() => {
        'data': {
          'enrolled_courses': 5,
          'completed_courses': 1,
          'pending_assignments': 2,
          'certificates': 1,
          'unread_notifications': 3,
          'recent_courses': [
            {
              'id': 1,
              'title': 'Artificial Intelligence (AI)',
              'slug': 'artificial-intelligence',
              'description': 'Master AI concepts and applications.',
              'image': null,
              'icon': 'brain',
              'duration': '12 Weeks',
              'learning_mode': 'hybrid',
              'requirements': null,
              'category': 'professional',
              'price': '0',
              'status': 'active',
              'progress': '75',
            },
            {
              'id': 3,
              'title': 'Web Development',
              'slug': 'web-development',
              'description': 'Build modern web applications.',
              'image': null,
              'icon': 'code',
              'duration': '14 Weeks',
              'learning_mode': 'online',
              'requirements': null,
              'category': 'professional',
              'price': '0',
              'status': 'active',
              'progress': '60',
            },
            {
              'id': 4,
              'title': 'Digital Marketing',
              'slug': 'digital-marketing',
              'description': 'Learn modern marketing strategies.',
              'image': null,
              'icon': 'marketing',
              'duration': '10 Weeks',
              'learning_mode': 'hybrid',
              'requirements': null,
              'category': 'professional',
              'price': '0',
              'status': 'active',
              'progress': '90',
            },
          ],
        },
      };

  // ─── Courses (shared) ─────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _allCourses() => [
        {
          'id': 1,
          'title': 'Artificial Intelligence (AI)',
          'slug': 'artificial-intelligence',
          'description': 'Master AI concepts, machine learning, and neural networks.',
          'image': null,
          'icon': 'brain',
          'duration': '12 Weeks',
          'learning_mode': 'hybrid',
          'requirements': null,
          'category': 'professional',
          'price': '0',
          'status': 'active',
          'progress': '75',
        },
          {
            'id': 2,
            'title': 'Cybersecurity',
            'slug': 'cybersecurity',
            'description': 'Protect systems and networks from digital attacks.',
            'image': null,
            'icon': 'shield',
            'duration': '14 Weeks',
            'learning_mode': 'online',
            'requirements': null,
            'category': 'professional',
            'price': '0',
            'status': 'active',
          },
        {
          'id': 3,
          'title': 'Web Development',
          'slug': 'web-development',
          'description': 'Build modern web applications with HTML, CSS, JS, and frameworks.',
          'image': null,
          'icon': 'code',
          'duration': '14 Weeks',
          'learning_mode': 'online',
          'requirements': null,
          'category': 'professional',
          'price': '0',
          'status': 'active',
          'progress': '60',
        },
        {
          'id': 4,
          'title': 'Digital Marketing',
          'slug': 'digital-marketing',
          'description': 'Learn SEO, social media marketing, and content strategy.',
          'image': null,
          'icon': 'marketing',
          'duration': '10 Weeks',
          'learning_mode': 'hybrid',
          'requirements': null,
          'category': 'professional',
          'price': '0',
          'status': 'active',
          'progress': '90',
        },
          {
            'id': 5,
            'title': 'Data Analysis',
            'slug': 'data-analysis',
            'description': 'Analyze and interpret complex data sets.',
            'image': null,
            'icon': 'chart',
            'duration': '8 Weeks',
            'learning_mode': 'online',
            'requirements': null,
            'category': 'professional',
            'price': '0',
            'status': 'active',
          },
      ];

  static Map<String, dynamic> studentCourses() => {'data': _allCourses()};
  static Map<String, dynamic> tutorCourses() => {'data': _allCourses()};

  // ─── Lessons by course ────────────────────────────────────────────────────
  static final Map<int, List<Map<String, dynamic>>> _lessonsByCourse = {
    1: [
      {
        'id': 101,
        'course_id': 1,
        'title': 'Introduction to AI',
        'description': 'Overview of artificial intelligence and its history.',
        'file_path': 'uploads/lessons/ai_intro.pdf',
        'file_type': 'pdf',
        'created_at': '2025-01-10T09:00:00Z',
      },
      {
        'id': 102,
        'course_id': 1,
        'title': 'Machine Learning Fundamentals',
        'description': 'Supervised and unsupervised learning algorithms.',
        'file_path': 'uploads/lessons/ml_fundamentals.pdf',
        'file_type': 'pdf',
        'created_at': '2025-01-17T09:00:00Z',
      },
      {
        'id': 103,
        'course_id': 1,
        'title': 'Neural Networks Deep Dive',
        'description': 'Understanding neural network architectures.',
        'file_path': 'uploads/lessons/neural_nets.pdf',
        'file_type': 'notes',
        'created_at': '2025-01-24T09:00:00Z',
      },
      {
        'id': 104,
        'course_id': 1,
        'title': 'AI Ethics & Future',
        'description': 'Ethical considerations in AI development.',
        'file_path': 'uploads/lessons/ai_ethics.pptx',
        'file_type': 'ppt',
        'created_at': '2025-01-31T09:00:00Z',
      },
    ],
    2: [
      {
        'id': 201,
        'course_id': 2,
        'title': 'Network Security Basics',
        'description': 'Fundamentals of network security and threat analysis.',
        'file_path': 'uploads/lessons/network_security.pdf',
        'file_type': 'pdf',
        'created_at': '2025-02-05T09:00:00Z',
      },
      {
        'id': 202,
        'course_id': 2,
        'title': 'Ethical Hacking 101',
        'description': 'Introduction to penetration testing.',
        'file_path': 'uploads/lessons/ethical_hacking.pdf',
        'file_type': 'pdf',
        'created_at': '2025-02-12T09:00:00Z',
      },
    ],
    3: [
      {
        'id': 301,
        'course_id': 3,
        'title': 'HTML & CSS Fundamentals',
        'description': 'Building responsive web pages.',
        'file_path': 'uploads/lessons/html_css.pdf',
        'file_type': 'pdf',
        'created_at': '2025-01-15T09:00:00Z',
      },
      {
        'id': 302,
        'course_id': 3,
        'title': 'JavaScript Essentials',
        'description': 'Core JavaScript programming concepts.',
        'file_path': 'uploads/lessons/js_essentials.pdf',
        'file_type': 'pdf',
        'created_at': '2025-01-22T09:00:00Z',
      },
      {
        'id': 303,
        'course_id': 3,
        'title': 'React Framework',
        'description': 'Building modern UIs with React.',
        'file_path': 'uploads/lessons/react_intro.pptx',
        'file_type': 'ppt',
        'created_at': '2025-01-29T09:00:00Z',
      },
    ],
    4: [
      {
        'id': 401,
        'course_id': 4,
        'title': 'SEO Fundamentals',
        'description': 'Search engine optimization basics.',
        'file_path': 'uploads/lessons/seo.pdf',
        'file_type': 'pdf',
        'created_at': '2025-02-01T09:00:00Z',
      },
      {
        'id': 402,
        'course_id': 4,
        'title': 'Social Media Strategy',
        'description': 'Building effective social media campaigns.',
        'file_path': 'uploads/lessons/social_media.pdf',
        'file_type': 'pdf',
        'created_at': '2025-02-08T09:00:00Z',
      },
    ],
    5: [
      {
        'id': 501,
        'course_id': 5,
        'title': 'Data Analytics Overview',
        'description': 'Introduction to data analysis concepts.',
        'file_path': 'uploads/lessons/data_analytics.pdf',
        'file_type': 'pdf',
        'created_at': '2025-02-10T09:00:00Z',
      },
    ],
  };

  static Map<String, dynamic> lessons(int courseId) => {
        'data': _lessonsByCourse[courseId] ?? [],
      };

  // ─── Assignments ──────────────────────────────────────────────────────────
  static Map<String, dynamic> studentAssignments() => {
        'data': [
          {
            'id': 51,
            'course_id': 1,
            'title': 'AI Model Design',
            'instructions': 'Design a simple neural network for image classification.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-08-15T23:59:00Z',
            'course_title': 'Artificial Intelligence (AI)',
            'score': null,
            'feedback': null,
            'submitted': false,
            'submitted_at': null,
          },
          {
            'id': 52,
            'course_id': 3,
            'title': 'Build a Portfolio Website',
            'instructions': 'Create a personal portfolio site using HTML, CSS, and JS.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-08-20T23:59:00Z',
            'course_title': 'Web Development',
            'score': null,
            'feedback': null,
            'submitted': false,
            'submitted_at': null,
          },
          {
            'id': 53,
            'course_id': 4,
            'title': 'Social Media Campaign',
            'instructions': 'Plan and execute a mock digital marketing campaign.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-07-10T23:59:00Z',
            'course_title': 'Digital Marketing',
            'score': '85',
            'feedback': 'Excellent work! Your campaign strategy was well-researched and creative.',
            'submitted': true,
            'submitted_at': '2025-07-08T14:30:00Z',
          },
          {
            'id': 54,
            'course_id': 2,
            'title': 'Security Audit Report',
            'instructions': 'Conduct a mock security audit on a small network.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-08-25T23:59:00Z',
            'course_title': 'Cybersecurity',
            'score': null,
            'feedback': null,
            'submitted': false,
            'submitted_at': null,
          },
        ],
      };

  // ─── Results (graded assignments) ─────────────────────────────────────────
  static Map<String, dynamic> studentResults() => {
        'data': [
          {
            'id': 53,
            'course_id': 4,
            'title': 'Social Media Campaign',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-07-10T23:59:00Z',
            'course_title': 'Digital Marketing',
            'score': '85',
            'feedback': 'Excellent work! Your campaign strategy was well-researched and creative.',
            'submitted': true,
            'submitted_at': '2025-07-08T14:30:00Z',
          },
          {
            'id': 55,
            'course_id': 1,
            'title': 'Machine Learning Basics Quiz',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '50',
            'due_date': '2025-06-30T23:59:00Z',
            'course_title': 'Artificial Intelligence (AI)',
            'score': '42',
            'feedback': 'Good understanding of core concepts. Review supervised learning algorithms.',
            'submitted': true,
            'submitted_at': '2025-06-28T10:15:00Z',
          },
          {
            'id': 56,
            'course_id': 3,
            'title': 'JavaScript Coding Challenge',
            'accepted_file_types': 'zip',
            'max_score': '100',
            'due_date': '2025-06-20T23:59:00Z',
            'course_title': 'Web Development',
            'score': '91',
            'feedback': 'Outstanding! Your code is clean and well-structured.',
            'submitted': true,
            'submitted_at': '2025-06-18T16:45:00Z',
          },
        ],
      };

  // ─── Certificates ─────────────────────────────────────────────────────────
  static Map<String, dynamic> studentCertificates() => {
        'data': [
          {
            'id': 1,
            'course_title': 'Digital Marketing',
            'certificate_number': 'IDAT-CERT-2025-001',
            'file_path': 'uploads/certificates/digital_marketing.pdf',
            'issue_date': '2025-03-15',
          },
        ],
      };

  // ─── Notifications ────────────────────────────────────────────────────────
  static Map<String, dynamic> studentNotifications() => {
        'data': [
          {
            'id': 1,
            'type': 'lesson',
            'title': 'New lesson available',
            'message': 'New AI lesson "Neural Networks Deep Dive" has been added to your course.',
            'is_read': false,
            'created_at': '2025-07-26T10:00:00Z',
          },
          {
            'id': 2,
            'type': 'assignment',
            'title': 'Assignment deadline approaching',
            'message': 'Your "AI Model Design" assignment is due in 3 days.',
            'is_read': false,
            'created_at': '2025-07-25T09:00:00Z',
          },
          {
            'id': 3,
            'type': 'certificate',
            'title': 'Certificate Awarded!',
            'message': 'Congratulations! You earned a certificate in Digital Marketing.',
            'is_read': false,
            'created_at': '2025-07-20T14:00:00Z',
          },
          {
            'id': 4,
            'type': 'completion',
            'title': 'Course progress milestone',
            'message': 'You\'ve completed 90% of Digital Marketing. Keep going!',
            'is_read': true,
            'created_at': '2025-07-15T11:00:00Z',
          },
          {
            'id': 5,
            'type': 'announcement',
            'title': 'Welcome to IDAT Academy',
            'message': 'We\'re excited to have you onboard! Start exploring your courses.',
            'is_read': true,
            'created_at': '2025-01-05T08:00:00Z',
          },
        ],
      };

  // ─── Tutor dashboard ─────────────────────────────────────────────────────
  static Map<String, dynamic> tutorDashboard() => {
        'data': {
          'total_students': 24,
          'total_courses': 5,
          'pending_submissions': 3,
          'total_lessons': 12,
          'courses': _allCourses(),
        },
      };

  // ─── Tutor assignments ───────────────────────────────────────────────────
  static Map<String, dynamic> tutorAssignments() => {
        'data': [
          {
            'id': 1,
            'course_id': 1,
            'title': 'AI Model Design',
            'instructions': 'Design a simple neural network for image classification.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-08-15T23:59:00Z',
            'course_title': 'Artificial Intelligence (AI)',
          },
          {
            'id': 2,
            'course_id': 3,
            'title': 'Build a Portfolio Website',
            'instructions': 'Create a personal portfolio site using HTML, CSS, and JS.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-08-20T23:59:00Z',
            'course_title': 'Web Development',
          },
          {
            'id': 3,
            'course_id': 4,
            'title': 'Social Media Campaign',
            'instructions': 'Plan and execute a mock digital marketing campaign.',
            'accepted_file_types': 'pdf,doc,docx,zip',
            'max_score': '100',
            'due_date': '2025-07-10T23:59:00Z',
            'course_title': 'Digital Marketing',
          },
        ],
      };

  // ─── Tutor students ───────────────────────────────────────────────────────
  static Map<String, dynamic> tutorStudents() => {
        'data': [
          {
            'id': 101,
            'first_name': 'John',
            'last_name': 'Doe',
            'email': 'john.doe@example.com',
            'phone': '+2348012345678',
            'enrollment_status': 'active',
          },
          {
            'id': 102,
            'first_name': 'Jane',
            'last_name': 'Smith',
            'email': 'jane.smith@example.com',
            'phone': '+2348023456789',
            'enrollment_status': 'active',
          },
          {
            'id': 103,
            'first_name': 'Michael',
            'last_name': 'Okafor',
            'email': 'michael.okafor@example.com',
            'phone': '+2348034567890',
            'enrollment_status': 'active',
          },
          {
            'id': 104,
            'first_name': 'Chioma',
            'last_name': 'Nwachukwu',
            'email': 'chioma.n@example.com',
            'phone': '+2348045678901',
            'enrollment_status': 'active',
          },
          {
            'id': 105,
            'first_name': 'Ahmed',
            'last_name': 'Bello',
            'email': 'ahmed.bello@example.com',
            'phone': '+2348056789012',
            'enrollment_status': 'pending',
          },
        ],
      };

  // ─── Tutor submissions ────────────────────────────────────────────────────
  static Map<String, dynamic> tutorSubmissions(int assignmentId) => {
        'data': [
          {
            'id': 1001,
            'assignment_id': assignmentId,
            'student_name': 'Jane Smith',
            'file_path': 'uploads/submissions/portfolio_jane.pdf',
            'typed_response': '',
            'submitted_at': '2025-07-18T11:30:00Z',
            'score': null,
            'feedback': null,
          },
          {
            'id': 1002,
            'assignment_id': assignmentId,
            'student_name': 'Michael Okafor',
            'file_path': 'uploads/submissions/portfolio_michael.pdf',
            'typed_response': 'Here is my portfolio website.',
            'submitted_at': '2025-07-19T15:45:00Z',
            'score': null,
            'feedback': null,
          },
          {
            'id': 1003,
            'assignment_id': assignmentId,
            'student_name': 'Chioma Nwachukwu',
            'file_path': null,
            'typed_response': 'I have completed the assignment. Please find my work attached.',
            'submitted_at': '2025-07-20T09:15:00Z',
            'score': '88',
            'feedback': 'Great work! Your portfolio looks professional.',
          },
        ],
      };

  // ─── Tutor profile ────────────────────────────────────────────────────────
  static Map<String, dynamic> tutorProfile() => {
        'data': {
          'id': 201,
          'first_name': 'Sarah',
          'last_name': 'Johnson',
          'email': tutorEmail,
          'phone': '+2348098765432',
          'photo': null,
          'bio': 'Senior instructor with 8+ years of experience in software development and cybersecurity.',
        },
      };
}
