# IDAT Academy Flutter App

A complete, stunning, professional Flutter mobile application for the IDAT Academy learning platform — supporting both **Student** and **Tutor** portals.

---

## 📱 Features

### Student Portal
- 🏠 **Dashboard** — Stats (enrolled courses, completed, pending, certificates), quick actions, continue learning section
- 📚 **My Courses** — Full list of enrolled courses with progress bars
- 📖 **Lessons** — View and download course lessons (PDF, PPT, Notes)
- 📝 **Assignments** — Submit assignments (file upload or typed response), view grades & feedback
- 📊 **Results** — Visual score tracker with overall average
- 🏆 **Certificates** — Download issued certificates
- 🔔 **Notifications** — Real-time notifications with read/unread states
- 👤 **Profile** — Update personal info, change password, logout

### Tutor Portal
- 🏠 **Dashboard** — Stats (students, courses, pending reviews, lessons)
- 📤 **Lessons** — Upload lessons (PDF/PPT/Notes) per course
- 📝 **Assignments** — Create assignments with due dates; grade submissions with score + feedback
- 👥 **Students** — View and search enrolled students
- 📢 **Announcements** — Send announcements to all students or per course
- 👤 **Profile** — View bio and logout

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter 3.x installed (`flutter --version`)
- Android Studio / VS Code with Flutter plugin
- Android device or emulator (API 21+)
- Your IDAT Academy PHP backend running

### Step 1 — Configure API URL

Open `lib/services/api_service.dart` and update line 7:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP/idat-academy-portal/api';
```

Replace `YOUR_SERVER_IP` with:
- Your local machine IP (e.g. `192.168.1.10`) for device testing
- `10.0.2.2` for Android emulator (maps to localhost)
- Your domain/hosting URL for production

### Step 2 — Install dependencies

```bash
cd idat_academy_app
flutter pub get
```

### Step 3 — Run the app

```bash
# For Android device/emulator
flutter run

# For release APK
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎨 Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#1B0151` | App bar, headers, primary brand |
| Secondary | `#273BE9` | Buttons, active states, links |
| Accent | `#F2BC12` | Highlights, certificates, CTAs |
| Success | `#10B981` | Completion, positive states |
| Warning | `#F59E0B` | Pending, due dates |
| Error | `#EF4444` | Errors, overdue |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry + routing
├── theme/
│   └── app_theme.dart         # Colors, typography, Material theme
├── models/
│   └── models.dart            # All data models
├── services/
│   └── api_service.dart       # All API calls (configured here)
├── providers/
│   └── auth_provider.dart     # Auth state management
├── widgets/
│   └── shared_widgets.dart    # Reusable UI components
└── screens/
    ├── auth/
    │   ├── splash_screen.dart
    │   └── login_screen.dart
    ├── student/
    │   ├── student_shell.dart         # Bottom nav wrapper
    │   ├── student_dashboard_screen.dart
    │   ├── student_courses_screen.dart
    │   ├── student_lessons_screen.dart
    │   ├── student_assignments_screen.dart
    │   ├── student_results_screen.dart
    │   ├── student_certificates_screen.dart
    │   ├── student_notifications_screen.dart
    │   └── student_profile_screen.dart
    └── tutor/
        ├── tutor_shell.dart            # Bottom nav wrapper
        ├── tutor_dashboard_screen.dart
        ├── tutor_screens.dart          # Lessons, Students, Announcements
        ├── tutor_assignments_screen.dart  # Assignments + grading
        └── (profile in tutor_shell.dart)
```

---

## 🔌 API Endpoints Used

All calls go to `YOUR_BASE_URL/api/...` with header `X-API-Key: idat_live_k8x2m9p4q7w1e5r3t6y0u`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `student/login` | POST | Student auth |
| `tutor/login` | POST | Tutor auth |
| `student/dashboard` | GET | Dashboard stats |
| `student/courses` | GET | Enrolled courses |
| `student/lessons?course_id=X` | GET | Course lessons |
| `student/assignments` | GET | All assignments |
| `student/assignments/:id/submit` | POST | Submit assignment |
| `student/results` | GET | Graded assignments |
| `student/certificates` | GET | Issued certificates |
| `student/notifications` | GET | Notifications |
| `student/profile` | GET/PUT | Profile management |
| `student/change-password` | POST | Change password |
| `tutor/dashboard` | GET | Tutor stats |
| `tutor/courses` | GET | Tutor's courses |
| `tutor/lessons` | GET/POST | View/upload lessons |
| `tutor/assignments` | GET/POST | View/create assignments |
| `tutor/submissions?assignment_id=X` | GET | View submissions |
| `tutor/submissions/:id` | PUT | Grade submission |
| `tutor/students` | GET | Student list |
| `tutor/announcements` | POST | Send announcements |

---

## 🛠️ Customization

### Change API Key
Update `ApiService.apiKey` in `lib/services/api_service.dart` to match your backend.

### App Name
- Android: Edit `android/app/src/main/AndroidManifest.xml` → `android:label`
- Everywhere: The app name is `IDAT Academy` throughout the UI

### Colors
All colors are centralized in `lib/theme/app_theme.dart` in the `AppColors` class.

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | REST API calls |
| `flutter_secure_storage` | Secure token storage |
| `file_picker` | Pick files for submission/upload |
| `url_launcher` | Open PDFs and external links |
| `dio` | File downloads |
| `shimmer` | Loading skeleton animations |
| `intl` | Date formatting |
| `fl_chart` | Progress charts |
| `percent_indicator` | Circular/linear progress |
| `cached_network_image` | Image caching |

---

## ⚠️ Notes

1. The app uses `usesCleartextTraffic="true"` for development (HTTP support). For production, use HTTPS and remove this.
2. Token is stored securely using `flutter_secure_storage` (uses Android Keystore).
3. Pull-to-refresh is available on all list screens.
4. The app auto-routes based on stored auth token on launch.

---

*Built for IDAT Academy · Flutter 3.x · Material Design 3*
