# Production notification delivery

The Android app receives Firebase Cloud Messaging (FCM) alerts, displays an audible high-priority notification when it is foregrounded, requests Android 13+ notification permission, and opens the in-app notification centre when the alert is tapped.

`android/app/google-services.json` is installed locally and intentionally ignored by Git. It identifies the Android Firebase project but is not a server credential.

## Required server endpoints

The existing authenticated API must implement these endpoints:

| Endpoint | Request | Purpose |
| --- | --- | --- |
| `POST /notifications/devices` | `{ token, platform }` | upsert the authenticated user's FCM token |
| `POST /notifications/devices/remove` | `{ token }` | deactivate the token on logout |
| `POST /notifications/send` | `{ userIds, title, body, type, relatedId, email }` | staff-only delivery endpoint |

`/notifications/send` must create the in-app notification record first, then send FCM to each active device token. Include `notification`, `data.type`, and `data.relatedId` in the FCM message. Android notification messages must use `channel_id: idat_academy_alerts` and sound `default`.

## Email through Brevo

Store the Brevo API key only in the server's secret manager/environment, for example `BREVO_API_KEY`; do not put it in Flutter, Git, or a Firebase config file. After the in-app record is created, the same server job can call Brevo's transactional email API for recipients that have email notifications enabled. Use a verified sender domain/address in Brevo.

Suggested email preference fields are `email_notifications`, `push_notifications`, and `announcement_notifications`; check them before each send. If an email request fails, retain the in-app notification and log/retry the email job rather than failing the whole announcement.

## Test checklist

1. Run on a physical Android device and accept the notification permission.
2. Sign in, then verify the API saved the current FCM token.
3. Send an announcement through the protected server endpoint.
4. Verify sound/banner in the foreground, system notification in the background, tap-to-open behaviour, in-app record, and Brevo email.
