# IDAT Academy: required live API fixes

These are confirmed issues from testing the Flutter app against `https://idat.ng/api`. Please deploy and test these fixes on the production server.

## 1. Restore login — urgent

`POST /api/login` returned HTTP `404` during the latest verification. Restore the route/rewrite rule and return JSON.

The request body is:

```json
{"email":"user@example.com","password":"password","portal":"student"}
```

`portal` is `student` for students and `tutor` for every Staff workspace user (Tutor, Staff, Manager, etc.). On success return:

```json
{"access_token":"...","account_type":"staff","role":"tutor","user":{"id":1,"first_name":"...","last_name":"...","email":"..."}}
```

The supplied default Staff account previously returned `401`; please verify it exists, is active, and has the correct password/role.

## 2. Fix Tutor lesson PDF upload

Implement `POST /api/lessons` for authorized Tutors. It receives `multipart/form-data`:

```text
course_id, title, description, file_type, file
```

The app sends `Authorization: Bearer <token>` and asks for JSON. The server must save the PDF and return JSON only:

```json
{"data":{"id":101,"course_id":12,"title":"...","file_path":"uploads/lessons/file.pdf","file_type":"pdf"}}
```

Do not return a PHP warning, HTML error page, empty body, or redirect. Those cause the app's “invalid JSON” message. Check PHP/server error logs, upload permissions, `upload_max_filesize`, `post_max_size`, and Apache/Nginx route rules.

## 3. Implement Tutor assignment creation

Implement `POST /api/assignments` for authorized Tutor/Staff users. The app sends JSON:

```json
{"course_id":12,"title":"...","instructions":"...","max_score":100,"accepted_file_types":"pdf,doc,docx,zip","due_date":"2026-08-15T23:59:00Z"}
```

Return HTTP `201` and:

```json
{"data":{"id":51,"course_id":12,"title":"...","instructions":"...","max_score":100,"accepted_file_types":"pdf,doc,docx,zip","due_date":"2026-08-15T23:59:00Z"}}
```

The server currently reports “method not found.” The CORS preflight permits POST, but the actual route/controller must be added or repaired.

## 4. Provide working certificate PDFs

`GET /api/certificates` must return a PDF link for each issued certificate as one of:

```json
{"file_path":"uploads/certificates/cert.pdf"}
```

or

```json
{"download_url":"https://idat.ng/storage/certificates/cert.pdf"}
```

Ensure the returned PDF URL is accessible to the signed-in student. The app now displays an error instead of silently doing nothing when no link is supplied.

## 5. Security requirement

The app no longer sends the shared `X-API-Key` with authenticated requests because it allowed a Student to access the staff-only `/api/students` endpoint. Enforce permissions using the Bearer token and role/account type on every protected endpoint. Never treat the app's public API key as admin identity.

## Expected JSON error format

All routes must respond with JSON, including failures:

```json
{"error":"Human-readable error message","status":400}
```

## Test checklist after deployment

1. Student login returns `200` and enters Student area.
2. Tutor login returns `200`, `account_type: staff`, `role: tutor` and enters Staff area.
3. Default Staff login returns `200`, `account_type: staff`, `role: staff` and enters Staff area.
4. Student cannot call `/api/students` (`403`); Tutor can (`200`).
5. Tutor can create assignment (`201`) and upload PDF lesson (`201`).
6. Student can open a valid certificate PDF.
