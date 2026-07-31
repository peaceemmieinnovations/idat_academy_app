# AI gateway deployment

Deploy `ai.php` beside the API and add this Apache route:

```apache
RewriteCond %{REQUEST_URI} ^/api/ai/lessons/[0-9]+/chat$
RewriteRule ^(.*)$ ai.php [L]
```

Set up to three keys for each provider in the server environment (never Flutter, Git, or `.env` committed to source): `GROQ_API_KEY_1` through `_3`, and `GEMINI_API_KEY_1` through `_3`. The gateway shuffles configured keys and falls back to the other provider when a request fails.

Before going live, confirm the real table/column names for `enrollments`, `lessons`, and `lesson_chunks`; the supplied queries document the required access check and chunk schema. Add a per-user rate limit at the web server or API gateway.

Do not use the shared `X-API-Key` as user authentication. It is embedded in the current app and must not grant admin access. AI requests require a Bearer token.
