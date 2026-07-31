# IDAT Academy AI: production handoff for the web developer

## Goal

Deploy AI features behind `https://idat.ng/api`. The Flutter application already calls the academy API; it must **never** call Groq or Gemini directly or contain their keys.

## Files supplied

- `missing-api-php/ai.php` — Pure-PHP Study Companion endpoint and Groq/Gemini fallback gateway.
- `missing-api-php/AI_SETUP.md` — hosting and secret configuration.
- `AI_FEATURES_API.md` — complete functional/API contract.

## Required production endpoints

| Endpoint | Who can use it | Purpose |
|---|---|---|
| `POST /api/ai/lessons/{lessonId}/chat` | enrolled student | Answer only from that lesson's extracted text |
| `POST /api/ai/assignments/{assignmentId}/review` | assigned student | Practice-only feedback; never store a final grade |
| `GET /api/lessons/{lessonId}/ai-summary` | enrolled student | Return cached generated summary |
| `GET /api/lessons/{lessonId}/ai-quiz?count=5` | enrolled student | Return cached, stable quiz questions |
| `GET /api/ai/career-path` | signed-in student | Recommendations using only that student's approved records |

## Database work required

Use the existing `lessons`, `courses`, `enrollments`, `assignments`, `submissions`, and `users` tables. Add these tables (names may be changed to fit the existing schema):

```sql
CREATE TABLE lesson_chunks (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  lesson_id BIGINT UNSIGNED NOT NULL,
  heading VARCHAR(255) NULL,
  content MEDIUMTEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  INDEX lesson_chunks_lesson_position (lesson_id, position)
);

CREATE TABLE lesson_ai_content (
  lesson_id BIGINT UNSIGNED PRIMARY KEY,
  summary MEDIUMTEXT NULL,
  quiz_json JSON NULL,
  status ENUM('pending','ready','failed') NOT NULL DEFAULT 'pending',
  generated_at TIMESTAMP NULL
);

CREATE TABLE ai_request_log (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  feature VARCHAR(40) NOT NULL,
  provider VARCHAR(20) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ai_request_rate_limit (user_id, feature, created_at)
);
```

When a tutor uploads or edits a lesson, extract its PDF/notes text, split it into chunks of about 800–1,200 words, save them in `lesson_chunks`, then generate and save the summary/quiz in `lesson_ai_content`. Do that in a job/cron queue, not during the upload response.

## Provider keys and fallback

Set these as private server environment variables, not in source code, database records, or Flutter:

```text
GROQ_API_KEY_1, GROQ_API_KEY_2, GROQ_API_KEY_3
GEMINI_API_KEY_1, GEMINI_API_KEY_2, GEMINI_API_KEY_3
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-2.5-flash
```

The gateway should use an available key/provider, retry another only for timeouts, HTTP 429, or HTTP 5xx, and return a friendly `503` after all providers fail. Do not use six keys to bypass provider quotas; set appropriate rate limits per user (for example, 20 chat requests/hour and 5 assignment reviews/hour).

## Authentication and authorisation

1. Require `Authorization: Bearer <token>` for every AI endpoint.
2. Read user ID and `account_type` from the token server-side.
3. Before lesson chat, summary, or quiz, join lesson → course → enrollment and reject non-enrolled students with `403`.
4. Before assignment review, verify that assignment belongs to the student's course and the student is assigned/enrolled.
5. Never use the Flutter `X-API-Key` as user identity or admin access: it is embedded in the app.

## Required response shapes

```json
// chat
{"answer":"...","sources":[{"heading":"Account security","page":3}]}

// review
{"practice_score":78,"strengths":["..."],"improvements":["..."],"suggested_revision":"..."}

// summary
{"summary":"...","generated_at":"2026-07-31T00:00:00Z"}

// quiz
{"questions":[{"id":"lesson-12-q1","question":"...","options":["..."],"correct_option":1,"explanation":"..."}]}
```

## Deployment checklist

1. Install the PHP cURL extension and allow outbound HTTPS to Groq and Google.
2. Put `ai.php` in the API server and route `/api/ai/lessons/{id}/chat` to it.
3. Configure secrets in the hosting control panel/server environment and restart PHP-FPM/Apache.
4. Replace the sample table/column queries in `ai.php` with the exact live schema.
5. Implement the remaining four endpoints above using the same authentication, enrolment check, provider gateway, and cached data.
6. Test with a valid Student token: enrolled lesson returns `200`; a different course returns `403`; no token returns `401`.
7. Return JSON errors only; do not return provider errors or API keys to mobile devices.

## Important

This does not become live simply by sending files. A developer with access to the `idat.ng` server and database must deploy it, add the private keys, route the URLs, and match the queries to the actual schema. Once that is deployed, the app's Study Companion begins using it immediately.
