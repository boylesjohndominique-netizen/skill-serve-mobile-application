# Setup: Email OTP + Google Sign-In credentials

The mobile app now requires two external services. Both are free and take ~10 minutes to configure. Nothing works on the deployed backend until these env vars are set.

## 1. Brevo — sends the OTP emails (required)

Brevo's free tier sends 300 emails/day to **any** recipient after verifying only a sender address — no custom domain needed.

1. Sign up at https://app.brevo.com (free plan).
2. Verify a sender: **Profile → Senders, Domains & Dedicated IPs → Senders → Add a sender**. Use a real address you can open (e.g. your Gmail). Confirm the verification email.
3. Create SMTP credentials: **Profile → SMTP & API → SMTP → Generate new SMTP key**. Note the username/password it shows.
4. Add these to **Render → your backend service → Environment**:

```
MAIL_MAILER=smtp
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=<brevo smtp login, e.g. your.email@domain>
MAIL_PASSWORD=<brevo smtp key>
MAIL_FROM_ADDRESS=<the sender address you verified>
MAIL_FROM_NAME="${APP_NAME}"
```

5. Redeploy. Test by registering an account in the app — the 6-digit code should arrive in the inbox.

> Without this, registration still succeeds but no email is sent, so OTP verification is impossible. Render's logs will show mail errors — check them if codes don't arrive.

## 2. Google Cloud — Sign-In with Google (required for the Google button)

The app requests a Google ID token; the backend validates it against a client ID you must create.

> **GCP project `skillserve-508412` — configured:**
> - ✅ **Android client**: `505637339796-hrsdio0lk5r7cihvmisg5thvo89a9mha.apps.googleusercontent.com`
>   (package `com.example.skilllink_mobile` + debug SHA-1 — required for device sign-in, but **not** used in code/backend)
> - ✅ **Web client**: `505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com`
>   — baked into `lib/core/config/app_config.dart` (`AppConfig.googleWebClientId`, overridable with `--dart-define=GOOGLE_WEB_CLIENT_ID=...`) and used as `GOOGLE_CLIENT_ID` on the backend.
>
> Why two clients: on Android, `google_sign_in` requests an ID token whose audience is the **Web** client (passed as `serverClientId`), and the Laravel backend validates that same audience. Google only issues the token to the Android client when that Web client ID is supplied. The Web client's `client_secret` is **not** needed anywhere in this flow.

1. Go to https://console.cloud.google.com → select project **skillserve-508412**.
2. Configure the OAuth consent screen (**APIs & Services → OAuth consent screen**): External, app name, support email. Add test users if you keep it in "Testing" mode — every Google account that signs in must be listed there, or publish the app.
3. Create credentials (**APIs & Services → Credentials → Create credentials → OAuth client ID**):
   - **Android client** — ✅ already created: package `com.example.skilllink_mobile`, debug SHA-1 from `./gradlew signingReport` (needs JDK 17+). Add the release keystore SHA-1 to the same client before publishing.
   - **Web client** — ✅ created: `505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com`. **Its client ID is what the backend checks (`GOOGLE_CLIENT_ID`) and what the app passes as `serverClientId`** — both already set to this value.
4. Add to **Render environment** (then redeploy):

```
GOOGLE_CLIENT_ID=505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com
```

5. Add the same value to the local backend `.env` (WSL, repo `~/web-project-bsit3blk3group6`):

```bash
cd ~/web-project-bsit3blk3group6/backend
grep -q '^GOOGLE_CLIENT_ID=' .env || \
  echo 'GOOGLE_CLIENT_ID=505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com' >> .env
php artisan config:clear
```

The Flutter side uses `GoogleSignIn(serverClientId: AppConfig.googleWebClientId)`. If sign-out works but you get "PLUGINS_NOT_INSTALLED", `ApiException: 10`, or a bad-audience / 401 "invalid Google token" error: the Web client ID in `app_config.dart` is missing/wrong, or `GOOGLE_CLIENT_ID` on the backend isn't the **Web** client.

## 3. Local development

Copy the same variables into `backend/.env` on WSL. For quick local testing without Brevo, `MAIL_MAILER=log` writes OTP codes to `backend/storage/logs/laravel.log` — grab the code from there.

## Security notes

- The OTP is stored hashed (bcrypt), expires in 10 minutes, allows 5 wrong attempts, and resends are rate-limited to 1/minute per email.
- Google ID tokens are validated server-side (audience, expiry, email_verified) before any account is created or session issued.
- Never commit real credentials; keep them in Render's env vars and `.env` (gitignored).
