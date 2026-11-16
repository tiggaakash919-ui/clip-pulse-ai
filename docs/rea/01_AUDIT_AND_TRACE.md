# 01. PeakCut Architecture Audit & End-to-End Pipeline Trace

## 1. Upstream Repository Overview
- **Repository**: `https://github.com/haziqahmedqasmi/PeakCut.git`
- **Inspected Commit SHA**: `b3e403e27444b620a50a4ec1cf44b3afff9e9e45`
- **Feature Branch**: `rea-live-clipping`
- **Core Technology Stack**:
  - Python 3.10+ (Standard library `http.server`, `threading`, `subprocess`, `urllib`)
  - Audio/Video Ingest: `yt-dlp` for stream manifest probing and media extraction
  - Video Processing: `ffmpeg` & `ffprobe` for rolling segmented recording and 9:16 / original layout composition
  - Speech Recognition: `sherpa-onnx` (offline ONNX runtime for ASR)
  - Layout & Text Rendering: FFmpeg ASS subtitle filters and PIL (Pillow)
  - Persistence: SQLite / SQLAlchemy core, local JSON state files
  - Frontend: Single-file zero-build HTML/JS/CSS web dashboard (`web/index.html`)

---

## 2. Component-by-Component Audit

| Subsystem | Upstream Location | Upstream Capabilities | REA Enhancements & Fixes |
|---|---|---|---|
| **Server & Gate** | `studio/server.py` | Built-in HTTP server, rate limiter, session token gate, sync counter | Added `/api/live/quick` (1-click URL ingest), `/api/live/{jid}/pause`, `/api/live/{jid}/resume`, `/api/live/{jid}/state`, and `/api/system/preflight` endpoints |
| **Config** | `studio/config.py` | Environment variable parsing with defaults | Added `ASR_MODEL_FAMILY` ("whisper"), `ASR_LANGUAGE` ("hi"), `CLIPS_EXPORT_DIR`, `DISK_SAFETY_GB`, `RECONNECT_MAX_TRIES`, `RECONNECT_MAX_DELAY` |
| **Live Ingest & Buffer** | `studio/live.py` | Rolling segmented recording (6s segments, 20m buffer), crude retry | Full observable state machine (`IDLE` -> `VALIDATING` -> `RECORDING` -> `RECONNECTING` -> `PAUSED` -> `DRAINING` -> `STOPPED`), exponential backoff with jitter, upcoming/ended stream detection, disk safety circuit breaker |
| **Media Probing** | `studio/media.py` | yt-dlp metadata extraction, audio extraction, loudness analysis | Added rate-limit pause detection and stream status parsing (`is_upcoming`, `was_live`, `is_live`) |
| **ASR Speech-to-Text** | `studio/transcribe.py`, `studio/fetch_model.py` | Only English Parakeet TDT Transducer supported; joiner required | Added local Whisper ONNX support (`sherpa-onnx.OfflineRecognizer.from_whisper()`), multilingual language config, byte-level BPE space tokens decoding with word timestamps |
| **Brain & Prompts** | `studio/brain.py` | Prompts for moment finding, caption cleaning | Category presets (`gaming`, `podcast`, `irl`, `general`), sentence boundary snapping (`.`, `?`, `!`, Hindi `।`), explainable heuristic highlight scorer (fallback when semantic AI is off) |
| **Captions & Unicode** | `studio/roman.py`, `studio/render.py` | Devanagari filtered out in `drawable()`, forcing system fallback | Enabled Devanagari range `0x0900..0x097F` for Poppins font; added "original" aspect ratio mode (preserves 16:9); automatic export of rendered clips to local output folder |
| **Dashboard UI** | `web/index.html` | Live recording monitor cards | Added live state pills, pause/resume buttons, genre tag, reconnect count, and free disk space monitor |

---

## 3. End-to-End Pipeline Trace

```
[1. User submits YouTube URL]
        │
        ▼
[2. Validation & Preflight] ──> studio/live.py: normalize(), resolve()
        │                        • Distinguishes: upcoming vs. ended vs. active live
        │                        • Sets LiveState = "VALIDATING"
        ▼
[3. Segmented Rolling Capture] ──> studio/live.py: Session._ingest()
        │                           • Spawns ffmpeg stream copy to 6s segments
        │                           • Disk safety check (> 5.0 GB free)
        │                           • Exponential backoff with jitter on disconnect
        │                           • Sets LiveState = "RECORDING"
        ▼
[4. Multilingual ASR] ──────────> studio/transcribe.py: transcribe()
        │                          • sherpa-onnx Whisper ONNX (base/tiny/small)
        │                          • Hindi / Hinglish / English multilingual
        │                          • Generates word-level timestamps ({w, s, e})
        ▼
[5. Highlight Moment Scoring] ──> studio/brain.py: find_live_clips() / heuristic_highlight_scorer()
        │                          • Genre-aware prompt (Gaming / Podcast / IRL / General)
        │                          • Acoustic loudness z-score + speech density rate
        │                          • Sentence boundary snapping (., ?, !, ।)
        │                          • Minimum 15s - Maximum 60s conservative bounds
        ▼
[6. Video Composition] ─────────> studio/render.py: render_clip()
        │                          • Framing modes: blur / zoom / crop / original
        │                          • Burned-in ASS word captions (Poppins font)
        │                          • Devanagari & Latin unicode support
        ▼
[7. Persistence & Delivery] ────> studio/jobs.py & config.CLIPS_EXPORT_DIR
        │                          • Instant preview in web dashboard (/api/clips)
        │                          • File copied to data/exported_clips/clip_*.mp4
        │                          • Ready for manual approval or official API upload
```
