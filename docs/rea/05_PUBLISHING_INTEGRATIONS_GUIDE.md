# 05. Publishing Integrations Guide (YouTube Shorts & Instagram Reels)

## 1. Safety-First: The Manual Approval Architecture

For a personal-use MVP, **automatic unattended posting of raw unreviewed clips is dangerous**:
- An unintended, offensive, or out-of-context moment could be broadcast publicly.
- Platform copyright strikes or spam penalties could be triggered.

Therefore, Clip Pulse AI's REA design adheres to a **Manual-Approval-First** workflow:
1. All generated clips are saved locally to `data/exported_clips/` and presented in the dashboard with score, hook, and full transcript excerpt.
2. The user watches the clip in the dashboard player.
3. If approved, the user clicks **Publish to Shorts** or **Publish to Reels**, or copies the `.mp4` file directly.

---

## 2. YouTube Shorts Publishing (Official Google Data API v3)

### Prerequisites:
1. A Google Cloud Console project (`https://console.cloud.google.com/`).
2. Enabled **YouTube Data API v3**.
3. Configured **OAuth 2.0 Consent Screen** (App type: *External* with your personal email as test user).
4. Downloaded `client_secret.json` placed in `data/secrets/youtube_client_secret.json`.

### Official Resumable Upload Architecture:
YouTube requires a two-step resumable upload:
```
1. POST https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status
   Headers:
     Authorization: Bearer <ACCESS_TOKEN>
     Content-Type: application/json; charset=UTF-8
   Body:
     {
       "snippet": {
         "title": "<HOOK_TITLE> #Shorts",
         "description": "<CLIP_DESCRIPTION>\n\n#Shorts #Gaming #Highlights",
         "categoryId": "20"
       },
       "status": {
         "privacyStatus": "private"  // Always start private for safety!
       }
     }

2. Google returns HTTP 200 with 'Location: <UPLOAD_URL>' header.

3. PUT <UPLOAD_URL>
   Headers:
     Content-Type: video/mp4
     Content-Length: <FILE_SIZE>
   Body:
     <RAW_VIDEO_BYTES>
```

### Quota Economics:
- YouTube grants a free default quota of **10,000 units/day**.
- Each video upload costs **1,600 units**.
- This allows **up to 6 automated uploads per day** under the free tier without quota extension requests.

---

## 3. Instagram Reels Publishing (Meta Graph API)

### Prerequisites:
1. A Meta Developer App with **Instagram Graph API** enabled.
2. An **Instagram Professional Account** (Creator or Business) linked to a Facebook Page.
3. Long-lived User Access Token with `instagram_basic`, `instagram_content_publish`.

### The Localhost Limitation & Solution:
The standard Instagram Graph API requires a publicly accessible HTTPS video URL:
```
POST https://graph.facebook.com/v19.0/{ig_user_id}/media
  ?media_type=REELS
  &video_url=https://example.com/clip_123.mp4
  &caption=Epic+stream+moment
```
Because Clip Pulse AI runs locally on your Windows PC (`http://127.0.0.1`), Meta's servers cannot reach your local hard drive directly.

**Two supported solutions:**
1. **Cloudflared Tunnel / ngrok (Zero Config)**:
   Expose the `/api/clips/public/` endpoint via a secure, temporary HTTPS tunnel during publishing.
2. **Resumable Upload Protocol (`rupload.facebook.com`)**:
   Direct binary chunk upload without hosting a public URL.

---

## 4. Security & Credential Hygiene

- All OAuth tokens and refresh tokens are stored in the user-local `data/tokens/` directory.
- `data/` is excluded from version control via `.gitignore`.
- Secrets are never embedded in frontend code or transmitted to third-party tracking services.
