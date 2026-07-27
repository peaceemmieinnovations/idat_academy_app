# IDAT Academy AI Features and API Guide

## Current mobile-app behaviour

The app is intentionally in `demoMode` while the API is pending. It uses local sample data so the complete student and tutor experience can be tested without a server.

Demo credentials:

- Student: `student@idat.com` / `idat123`
- Staff: `tutor@idat.com` / `idat123`

Set `ApiService.demoMode` to `false` only after the backend endpoints below are deployed.

## Student learning tools

### AI Study Companion

The mobile UI sends a question with the active lesson ID. The backend retrieves extracted lesson text, selects relevant sections, and asks the AI provider to answer only from that context.

`POST /api/ai/lessons/{lessonId}/chat`

```json
{ "question": "Why is multi-factor authentication important?" }
```

```json
{ "answer": "...", "sources": [{ "heading": "Account security", "page": 3 }] }
```

### AI assignment reviewer

This is practice feedback, not a final tutor grade.

`POST /api/ai/assignments/{assignmentId}/review`

```json
{ "draft": "Student's typed or voice transcript" }
```

```json
{ "practice_score": 78, "strengths": ["..."], "improvements": ["..."], "suggested_revision": "..." }
```

### AI summaries and quiz practice

When a tutor uploads a lesson, queue a background job to extract text, create a short summary and generate quiz questions. Do not make the upload request wait for the AI model.

- `GET /api/lessons/{lessonId}/ai-summary`
- `GET /api/lessons/{lessonId}/ai-quiz?count=5`

Store the generated quiz with stable question IDs so learners see consistent practice content.

### Voice-to-text drafts

Voice recognition is performed by the student device with Flutter `speech_to_text`. The editable transcript is sent through the existing assignment-submission endpoint just like a typed answer.

`POST /api/student/assignments/{assignmentId}/submit`

```json
{ "typed_response": "Edited speech transcript", "source": "voice" }
```

Do not upload raw microphone audio without explicit consent and a retention policy.

### Career Path Advisor

Use only the signed-in student's completed courses, grades, skills and approved available job data.

`GET /api/ai/career-path`

```json
{
  "recommended_role": "Junior Cybersecurity Analyst",
  "next_courses": ["Network Security", "Linux Fundamentals"],
  "skill_gaps": ["Linux command line"],
  "portfolio_actions": ["Create a security checklist"],
  "roles_to_explore": ["SOC Analyst", "Security Intern"]
}
```

## Tutor workflow

1. Tutor uploads a PDF, presentation or notes file.
2. Backend stores the file and creates a processing record.
3. A worker extracts text, chunks it and stores the chunks.
4. The worker generates a summary and quiz, then marks processing complete.
5. Students read the saved summary, take the saved quiz, and use the lesson chunks as Study Companion context.

## Security requirements

- Keep AI-provider keys on the backend only; never ship them in Flutter.
- Authenticate every AI request and verify course enrollment.
- Add rate limits, logging and content-safety handling.
- Clearly label reviewer scores as practice guidance; tutor grades remain authoritative.
- Request microphone permission only when a student starts transcription.
