# IDAT Academy App — Full API Contract

Base URL: `https://idat.ng/api`

Headers:
- `Content-Type: application/json`
- `X-API-Key: idat_live_k8x2m9p4q7w1e5r3t6y0u`
- `Authorization: Bearer <token>` (after login)

---

## IMPORTANT: RBAC Rules (from Backend Docs)

| Account Type | Role | Access Level |
|---|---|---|
| `admin` | any | Full access to all resources |
| `staff` | `tutor`, `staff`, `manager`, etc. | Own teaching resources, students, submissions |
| `student` | — | Own data only (enrollments, submissions, certificates, notifications) |

Key implications for the Flutter app:
- **`GET /api/stats` is admin-only** — Student/tutor dashboards use other endpoints
- **`GET /api/settings` is admin-only** — App doesn't currently use settings anyway
- **`GET /api/enrollments`** — Students auto-filtered to own records
- **`POST /api/enrollments`** — Admin/staff only (students can't self-enroll via API)
- **`GET /api/certificates`** — Students see only their own
- **`GET /api/notifications`** — Students see only their own
- **`PUT /api/notifications/{id}`** — Admin only (students can't mark read via API)
- **`GET /api/submissions`** — Students see only their own
- **`GET /api/students`** — Admin/staff only (students can't list all students)
- **`GET /api/applications`** — Admin/staff only
- **`GET /api/attendance`** — Staff see only their own records

---

## SECTION 1: Endpoints Already Present (needs verification)

### 1.1 POST /api/login
**Purpose:** Unified login for students & tutors
**Request:**
```json
{ "email": "user@example.com", "password": "...", "portal": "student|tutor" }
```
**Success Response (200):**
```json
{
  "access_token": "1|abc123...",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "account_type": "student",
  "role": "student",
  "user": {
    "id": 101,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+2348012345678",
    "photo": null,
    "status": "active"
  }
}
```
**Used by:** LoginScreen → auth_provider.dart

### 1.2 GET /api/stats
**Purpose:** Dashboard statistics for both student & tutor
**App expects:** Counts and recent courses
**Success Response (200) — Must contain these keys:**
```json
{
  "data": {
    "students": { "total": 150, "active": 120 },
    "courses": { "total": 10, "active": 8 },
    "enrollments": { "total": 300, "active": 250, "completed": 50 },
    "assignments": { "total": 60, "pending": 15, "graded": 45 },
    "certificates": { "total": 40 },
    "notifications": { "total": 200, "unread": 25 }
  }
}
```
**Note:** The app currently normalizes this to extract counts. However for best results, add student-specific stats that include `recent_courses` array (see Section 2).

### 1.3 GET /api/courses
**Purpose:** List all courses (public, for students, for tutors)
**Query Params:** `?page=1&per_page=20&tutor_id=X&category=...`
**Success Response:**
```json
{
  "data": [
    {
      "id": 1,
      "title": "Artificial Intelligence (AI)",
      "slug": "artificial-intelligence",
      "description": "Master AI concepts...",
      "image": null,
      "icon": "brain",
      "duration": "12 Weeks",
      "learning_mode": "hybrid",
      "requirements": null,
      "category": "professional",
      "price": "0",
      "status": "active",
      "progress": null
    }
  ],
  "pagination": { "current_page": 1, "per_page": 20, "total": 10, "last_page": 1 }
}
```
**IMPORTANT:** The Course model reads these exact field names:
- `id`, `title`, `slug`, `description`, `image`, `icon`, `duration`
- `learning_mode`, `requirements`, `category`, `price`, `status`, `progress`

### 1.4 GET /api/courses/{id}
**Purpose:** Single course details
**Used by:** Course detail screens

### 1.5 GET /api/enrollments
**Purpose:** Student's enrolled courses (replaces old `student/courses`)
**Query Params:** `?student_id=X&status=enrolled`
**Success Response (same course format as 1.3 with `progress`):**
```json
{
  "data": [
    {
      "id": 1,
      "course_id": 1,
      "student_id": 101,
      "status": "enrolled",
      "progress": 75,
      "course": {
        "id": 1, "title": "...", "slug": "...", "description": "...",
        "image": null, "icon": "brain", "duration": "12 Weeks",
        "learning_mode": "hybrid", "category": "professional",
        "price": "0", "status": "active"
      }
    }
  ]
}
```
**Note:** The app reads `res['data']` and maps each item through `Course.fromJson`. So either return course objects directly, or nest them under a `course` key (and the app will need `course_id` mapped to `id`).

### 1.6 POST /api/enrollments
**Purpose:** Enroll student in a course
**Request:** `{ "student_id": 101, "course_id": 5 }`
**Response (201):** `{ "message": "Enrolled successfully", "data": { "id": 10, ... } }`

### 1.7 GET /api/lessons
**Purpose:** List lessons for a course
**Query:** `?course_id=1`
**Response:**
```json
{
  "data": [
    {
      "id": 101,
      "course_id": 1,
      "title": "Introduction to AI",
      "description": "Overview of artificial intelligence.",
      "file_path": "uploads/lessons/ai_intro.pdf",
      "file_type": "pdf",
      "created_at": "2025-01-10T09:00:00Z"
    }
  ]
}
```

### 1.8 POST /api/lessons
**Purpose:** Tutor uploads a lesson (multipart or JSON)
**Multipart fields:** `course_id`, `title`, `description`, `file_type`, `file`

### 1.9 GET /api/assignments
**Purpose:** List assignments (for student or tutor)
**Query:** `?course_id=X&student_id=X`
**Response (student view needs submission info):**
```json
{
  "data": [
    {
      "id": 51,
      "course_id": 1,
      "title": "AI Model Design",
      "instructions": "Design a simple neural network...",
      "accepted_file_types": "pdf,doc,docx,zip",
      "max_score": "100",
      "due_date": "2025-08-15T23:59:00Z",
      "course_title": "Artificial Intelligence (AI)",
      "score": null,
      "feedback": null,
      "submitted": false,
      "submitted_at": null
    }
  ]
}
```
**IMPORTANT:** For student view, the app needs `score`, `feedback`, `submitted` (bool), `submitted_at` per assignment. This means you need to join with submissions table when the request has a student context.

### 1.10 GET /api/submissions
**Purpose:** List submissions for an assignment (tutor view)
**Query:** `?assignment_id=1`
**Response:**
```json
{
  "data": [
    {
      "id": 1001,
      "assignment_id": 1,
      "student_id": 102,
      "student_name": "Jane Smith",
      "file_path": "uploads/submissions/portfolio_jane.pdf",
      "typed_response": "",
      "submitted_at": "2025-07-18T11:30:00Z",
      "score": null,
      "feedback": null
    }
  ]
}
```

### 1.11 POST /api/submissions
**Purpose:** Student submits assignment (multipart or JSON)
**Body:** `{ "assignment_id": 51, "student_id": 101, "typed_response": "..." }` + file

### 1.12 PUT /api/submissions/{id}
**Purpose:** Tutor grades a submission
**Body:** `{ "score": 85, "feedback": "Good work!", "graded_by": 201 }`

### 1.13 GET /api/certificates
**Purpose:** List student's certificates
**Query:** `?student_id=101`
**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "course_title": "Digital Marketing",
      "certificate_number": "IDAT-CERT-2025-001",
      "file_path": "uploads/certificates/digital_marketing.pdf",
      "issue_date": "2025-03-15"
    }
  ]
}
```

### 1.14 GET /api/notifications
**Purpose:** List notifications for a user
**Query:** `?student_id=101`
**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "type": "lesson|assignment|certificate|completion|announcement",
      "title": "New lesson available",
      "message": "New lesson added...",
      "is_read": false,
      "created_at": "2025-07-26T10:00:00Z"
    }
  ]
}
```

### 1.15 PUT /api/notifications/{id}
**Purpose:** Mark notification as read
**Body:** `{ "is_read": 1 }`

### 1.16 GET /api/students/{id}
**Purpose:** Get student profile
**Response:**
```json
{
  "id": 101,
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "+2348012345678",
  "photo": null,
  "address": "12, Awolowo Road, Ikoyi, Lagos",
  "status": "active"
}
```

### 1.17 PUT /api/students/{id}
**Purpose:** Update student profile
**Body:** `{ "first_name": "...", "last_name": "...", "phone": "...", "address": "...", "photo": "base64..." }`

### 1.18 GET /api/tutors/{id}
**Purpose:** Get tutor profile
**Response:** Same shape as student but with `bio` field

### 1.19 PUT /api/tutors/{id}
**Purpose:** Update tutor profile
**Body:** `{ "first_name": "...", "last_name": "...", "email": "...", "phone": "...", "bio": "...", "photo": "base64..." }`

### 1.20 POST /api/applications
**Purpose:** Public course application
**Body:**
```json
{
  "first_name": "...", "last_name": "...", "email": "...",
  "phone": "...", "gender": "male|female", "state": "...",
  "lga": "...", "address": "...", "education_level": "...",
  "occupation": "...", "how_heard": "...",
  "courses": ["AI", "Web Development"],
  "learning_mode": "online|hybrid"
}
```

### 1.21 POST /api/announcements
**Purpose:** Tutor creates announcement
**Body:** `{ "tutor_id": 201, "title": "...", "message": "...", "course_id": 1 }`

### 1.22 POST /api/attendance/scan
**Purpose:** Staff clock in/out
**Body (clock in):** `{ "action": "clock_in", "staff_id": 201, "method": "admin", "course_id": 1, "notes": "..." }`
**Body (clock out):** `{ "action": "clock_out", "staff_id": 201, "method": "admin", "clock_in": "2025-07-26T08:00:00Z", "duration_seconds": 28800, "notes": "..." }`

### 1.23 POST /api/course_outlines
**Purpose:** Save lesson outline
**Body:** `{ "course_id": 1, "tutor_id": 201, "topic": "...", "objectives": "...", "key_points": "...", "activities": "...", "assignment": "..." }`

### 1.24 GET /api/settings
**Purpose:** Get app settings
**Query:** `?keys=key1,key2`

---

## SECTION 2: Missing Endpoints That Need to Be Built

### 2.1 [MISSING] POST /api/change-password
**Purpose:** Allow student/tutor to change password
**Request:**
```json
{ "old_password": "current", "new_password": "newone" }
```
**Response:**
```json
{ "message": "Password changed successfully" }
```
**Used by:** `student_profile_screen.dart` → `ApiService.changeStudentPassword()`

### 2.2 [MISSING] POST /api/notifications/devices
**Purpose:** Register Firebase Cloud Messaging device token so push notifications work
**Request:**
```json
{ "token": "fcm_token_abc123", "platform": "android" }
```
**Response (201):**
```json
{ "message": "Device registered" }
```
**Used by:** `notification_service.dart` → `ApiService.registerDeviceToken()`

### 2.3 [MISSING] POST /api/notifications/devices/remove
**Purpose:** Unregister device token on logout
**Request:**
```json
{ "token": "fcm_token_abc123" }
```
**Response:**
```json
{ "message": "Device removed" }
```
**Used by:** `notification_service.dart` → `ApiService.unregisterDeviceToken()`

### 2.4 [MISSING] GET /api/students/{id}/dashboard (RECOMMENDED NEW ENDPOINT)
**Purpose:** Student-specific dashboard with counts AND recent courses
**The `/api/stats` endpoint only returns platform-wide counts, not student-specific data.**
**Response:**
```json
{
  "data": {
    "enrolled_courses": 5,
    "completed_courses": 1,
    "pending_assignments": 2,
    "certificates": 1,
    "unread_notifications": 3,
    "recent_courses": [
      {
        "id": 1,
        "title": "Artificial Intelligence (AI)",
        "slug": "artificial-intelligence",
        "description": "...",
        "image": null,
        "icon": "brain",
        "duration": "12 Weeks",
        "learning_mode": "hybrid",
        "category": "professional",
        "price": "0",
        "status": "active",
        "progress": 75
      }
    ]
  }
}
```
**Alternatively, add `student_id` query filter to `/api/stats`** to make it return student-scoped data.

### 2.5 [MISSING] GET /api/tutors/{id}/dashboard (RECOMMENDED NEW ENDPOINT)
**Purpose:** Tutor-specific dashboard
**Response:**
```json
{
  "data": {
    "total_students": 24,
    "total_courses": 5,
    "pending_submissions": 3,
    "total_lessons": 12,
    "courses": [ { "id": 1, "title": "...", ... } ]
  }
}
```

### 2.6 [MISSING] GET /api/assignments/graded
**Purpose:** Student's graded assignments (for Results screen)
**Currently falls back to `/api/assignments` which returns ALL assignments, not just graded**
**Query:** `?student_id=101&graded=true`
**Response:** Same format as 1.9 but filtered to only graded submissions

---

## SECTION 3: Critical PHP/Laravel Implementation Notes

### 3.1 Login Response MUST include `user` object with these keys:
- `id` (int), `first_name`, `last_name`, `email`, `phone`, `photo`, `status`

### 3.2 All list endpoints MUST wrap in `{ "data": [...] }`
The Flutter app reads `res['data']` on every list response.

### 3.3 Error format MUST be:
```json
{ "error": "Human-readable error message", "status": 400 }
```
The app checks `res['error'] != null` to detect errors.

### 3.4 File paths must be relative (e.g., `uploads/lessons/xyz.pdf`)
The app constructs full URLs as: `https://idat.ng/{file_path}`

### 3.5 Course objects MUST include `progress` field for enrolled students
Even if null for non-enrolled. The app displays a progress bar.

### 3.6 Assignments for students MUST include submission status
The student view requires: `score`, `feedback`, `submitted` (bool), `submitted_at` per assignment. This means the assignments endpoint needs to left-join submissions when a `student_id` filter is present.

### 3.7 Pagination format:
```json
{
  "data": [...],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

---

## Quick Summary: What to Build Next (Priority Order)

| Priority | Endpoint | Why |
|----------|----------|-----|
| P0 | `POST /api/notifications/devices` | Push notifications won't register without this |
| P0 | `POST /api/notifications/devices/remove` | Logout won't clean up device tokens |
| P0 | `POST /api/change-password` | Password change silently fails (falls to mock) |
| P1 | Make `GET /api/students/{id}` include `courses` array with progress | Student dashboard shows recent courses |
| P1 | Make `GET /api/tutors/{id}` include `students_count`, `lessons_count` | Tutor dashboard shows accurate counts |
| P1 | Make `GET /api/assignments` include `course_title` field | Assignment cards show course name |
| P1 | Make `PUT /api/notifications/{id}` accessible to notification owner (not just admin) | Students can mark notifications as read |
| P2 | Make `POST /api/enrollments` allow students to self-enroll | Course registration works for students |
| P2 | Make `GET /api/assignments` return assignments for student's enrolled courses | Student sees relevant assignments |

## PHP/Laravel Implementation Notes

The Flutter app expects these exact field names in the JSON responses:

**Login response** user object: `id`, `first_name`, `last_name`, `email`, `phone`, `photo`, `status`

**Course object**: `id`, `title`, `slug`, `description`, `image`, `icon`, `duration`, `learning_mode`, `requirements`, `category`, `price`, `status`, `progress`

**Enrollment object**: same as course, with `progress` (0-100) and `status` (enrolled/completed/dropped)

**Lesson object**: `id`, `course_id`, `title`, `description`, `file_path`, `file_type`, `created_at`

**Assignment object**: `id`, `course_id`, `title`, `instructions`, `accepted_file_types`, `max_score`, `due_date`, `course_title`

**Submission object**: `id`, `assignment_id`, `student_id`, `student_name`, `file_path`, `typed_response`, `submitted_at`, `score`, `feedback`

**Notification object**: `id`, `type`, `title`, `message`, `is_read` (boolean), `created_at`

**Error format**: `{ "error": "message", "status": 400 }` — the app checks `res['error'] != null`

**All list endpoints** must wrap results in `{ "data": [...] }`

**File paths** should be relative (e.g. `uploads/lessons/xyz.pdf`). The app constructs full URLs as `https://idat.ng/{file_path}`
