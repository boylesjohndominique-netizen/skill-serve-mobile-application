# Setup: Email OTP + Google Sign-In credentials

The mobile app now requires two external services. Both are free and take ~10 minutes to configure. Nothing works on the deployed backend until these env vars are set.

## 1. Gmail API — sends the 6-digit codes and every email (required)

Since 2026-10-06 the sign-up code, its resend and the forgot-password code are sent **as your Gmail
account through the Gmail API** — free, no domain, no email company to approve you (Brevo and
Mailjet both blocked new accounts; Twilio has no free trial in the Philippines). It uses the same
Google Cloud project as Google sign-in. Full click-by-click steps are in the web repo's
`DEPLOYMENT.md` → "Email codes — Gmail API". In short:

1. Enable the **Gmail API**; set the OAuth consent screen to **In production** (Publish app).
2. Create an OAuth client of type **Web application** with redirect URI
   `https://developers.google.com/oauthplayground`; copy its ID and secret.
3. In the OAuth Playground, with your own credentials, authorize the scope
   `https://www.googleapis.com/auth/gmail.send` as your Gmail and copy the **refresh token**.
4. Put them on Render (section 3).

## 2. Google Cloud — Sign-In with Google (required for the Google button)

The app requests a Google ID token; the backend validates it against a client ID you must create.

> **GCP project `skillserve-508412` — configured:**
> - ⚠️ **Android client — action needed.** The existing one
>   (`505637339796-hrsdio0lk5r7cihvmisg5thvo89a9mha…`) is registered for the old package
>   `com.example.skilllink_mobile`. The app is now **`com.skillserve.mobile`**, so Google sign-in fails
>   on Android until you create an Android client for the new package (step 3). It is not referenced in
>   code or on the backend — only the package name + SHA-1 must match.
> - ✅ **Web client**: `505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com`
>   — baked into `lib/core/config/app_config.dart` (`AppConfig.googleWebClientId`, overridable with `--dart-define=GOOGLE_WEB_CLIENT_ID=...`) and used as `GOOGLE_CLIENT_ID` on the backend.
>
> Why two clients: on Android, `google_sign_in` requests an ID token whose audience is the **Web** client (passed as `serverClientId`), and the Laravel backend validates that same audience. Google only issues the token to the Android client when that Web client ID is supplied. The Web client's `client_secret` is **not** needed anywhere in this flow.

1. Go to https://console.cloud.google.com → select project **skillserve-508412**.
2. Configure the OAuth consent screen (**APIs & Services → OAuth consent screen**): External, app name, support email. Add test users if you keep it in "Testing" mode — every Google account that signs in must be listed there, or publish the app.
3. Create credentials (**APIs & Services → Credentials → Create credentials → OAuth client ID**):
   - **Android client** — create one with package name **`com.skillserve.mobile`** and the SHA-1
     fingerprints of every key that signs the app you install:
     - debug: `cd android && ./gradlew signingReport` (needs JDK 17+) → `Variant: debug` → `SHA1`;
     - release: `keytool -list -v -keystore <your-upload-keystore.jks> -alias upload` → `SHA1`
       (see README → "Building a release").
     Google Cloud accepts **one SHA-1 per Android client**, so create **two** Android clients with
     the same package name — one per fingerprint. Nothing in the app or backend changes.
     Fingerprints on the owner's machine (public, not secrets):
     - release (`C:/Users/earlf/skillserve-upload.jks`, alias `upload`):
       `20:30:88:71:1E:64:1B:EE:90:9B:E5:0C:7E:FE:E1:9D:75:E3:36:1A`
     - debug (`C:/Users/earlf/.android/debug.keystore`):
       `68:68:EE:E0:71:8A:F1:F5:38:F8:85:67:58:20:D9:91:86:01:B8:57`
     New clients can take minutes to hours to take effect; until then sign-in fails with
     `ApiException: 10`.
     `network_error` / `ApiException: 7` is different: the phone's Google Play services could not
     reach Google (offline, wrong date/time, VPN or Private DNS, outdated Play services, emulator
     without Play Store). The app retries once, then says so; nothing is sent to the backend.
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

## 3. The codes must be configured on RENDER, not just locally

The mobile app talks to the Render deployment, so the settings go in **Render → backend →
Environment**, then redeploy:

```
OTP_DRIVER=mail
MAIL_MAILER=gmail-api
GMAIL_CLIENT_ID=…apps.googleusercontent.com
GMAIL_CLIENT_SECRET=…
GMAIL_REFRESH_TOKEN=1//…
MAIL_FROM_ADDRESS=<the same Gmail>
MAIL_FROM_NAME=SkillServe
```

The Gmail API is reached over HTTPS, so Render's blocked SMTP ports do not matter. **Verify:**
`https://skillserve-web-backend.onrender.com/api/health` shows `"otp": {"status": "up", "driver":
"mail", "mailer": "gmail-api"}`. Then sign up in the app and try Forgot password — the emails also
appear in that Gmail's *Sent* folder. If a code does not arrive, Render → Logs shows
`Failed to send registration OTP` with Google's reason.

## 4. Local development

Copy the same variables into `backend/.env` on WSL. For quick local testing, `MAIL_MAILER=log` writes OTP codes to `backend/storage/logs/laravel.log` — grab the code from there.

## Security notes

- The OTP is stored hashed (bcrypt), expires in 10 minutes, allows 5 wrong attempts, and resends are rate-limited to 1/minute per email.
- Google ID tokens are validated server-side (audience, expiry, email_verified) before any account is created or session issued.
- Never commit real credentials; keep them in Render's env vars and `.env` (gitignored).
