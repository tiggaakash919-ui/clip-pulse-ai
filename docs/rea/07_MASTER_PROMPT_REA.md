# 07. Master Prompt for External REA (Reverse Engineering Anything) Agent

Copy and paste the prompt below into your REA agent or AI programming assistant to reproduce, audit, or extend this 24/7 continuous livestream clipping pipeline on any environment.

```markdown
You are REA, operating as an expert repository reverse-engineering agent, senior Python backend engineer, Windows deployment specialist, and multimedia video-pipeline QA engineer.

Your task is to inspect, clone, and extend the open-source ClipPulse repository into a working personal-use 24/7 continuous livestream clipping MVP:
Target Repository: https://github.com/tiggaakash919-ui/clip-pulse-ai.git
Upstream Reference Commit: b3e403e27444b620a50a4ec1cf44b3afff9e9e45
Working Feature Branch: rea-live-clipping

==================================================
1. PRODUCT GOAL & FIXED USER REQUIREMENTS
==================================================

Build on ClipPulse rather than rewriting it from scratch.

The user wants to paste ONE authorized YouTube livestream URL into a locally hosted dashboard on their Windows PC.
While that stream remains live, the application must continuously:
1. Record a bounded crash-tolerant rolling buffer (6-second chunks, 20-minute sliding window).
2. Transcribe new audio incrementally using local multilingual speech recognition (supporting Hindi, Hinglish, English, and code-switching with word-level timestamps).
3. Identify genuinely promising, self-contained moments using explainable multi-signal highlight scoring (loudness z-scores, speech rate, and sentence endings).
4. Snap clips strictly to 15–60 seconds, ending at natural sentence boundaries (., ?, !, or Hindi danda ।).
5. Produce vertical 9:16 clips (blur/zoom/crop) or preserve native source aspect ratio (original).
6. Render burnt-in bouncy word captions using the bundled Poppins-ExtraBold font with full Devanagari & Latin Unicode glyph support.
7. Automatically export rendered clips to a local folder (`data/exported_clips/`) while displaying them on the local web dashboard.
8. Support manual-approval-first publishing to YouTube Shorts and Instagram Reels.
9. Support continuous unattended 24/7 operation with automatic reconnect backoff with jitter and Windows sleep prevention.
10. Implement an observable state machine: IDLE, VALIDATING, WAITING_FOR_SOURCE, RECORDING, RECONNECTING, PAUSED, DRAINING, STOPPED, ERROR.

==================================================
2. UPSTREAM ARCHITECTURE AUDIT & EXTENSIONS
==================================================

Preserve working upstream conventions while implementing these specific enhancements:

1. `studio/config.py`:
   - Add `ASR_MODEL_FAMILY` ("whisper"), `ASR_LANGUAGE` ("hi"), `CLIPS_EXPORT_DIR`, `DISK_SAFETY_GB` (5.0), `RECONNECT_MAX_TRIES` (15), `RECONNECT_MAX_DELAY` (60.0).

2. `studio/fetch_model.py` & `studio/transcribe.py`:
   - Replace English-only NeMo Parakeet assumption with `sherpa-onnx.OfflineRecognizer.from_whisper()`.
   - Handle byte-level BPE space tokens ('Ġ', ' ', ' ') to preserve word-level timestamps.

3. `studio/brain.py`:
   - Implement category presets (`gaming`, `podcast`, `irl`, `general`) dynamically adapting prompts and scoring.
   - Implement `heuristic_highlight_scorer()` combining audio z-scores, dialogue rate, and sentence snapping as a fallback when semantic AI is offline.

4. `studio/roman.py` & `studio/render.py`:
   - Allow Devanagari Unicode codepoints (`0x0900..0x097F`) in `drawable()`.
   - Add `"original"` aspect ratio layout mode in `geometry()` and `_filter()`.
   - Copy finalized `.mp4` and `.jpg` clips to `config.CLIPS_EXPORT_DIR`.

5. `studio/live.py`:
   - Implement observable `LIVE_STATES` and `LiveSession.set_state()`, `pause()`, `resume()`.
   - Implement upcoming vs. ended stream detection (`StreamUpcoming`, `StreamEnded`).
   - Implement disk usage safety check.
   - Implement bounded exponential reconnect with jitter: `min(max_delay, 2**min(fails, 5) + jitter)`.
   - Implement `quick_live()` helper.

6. `studio/server.py` & `web/index.html`:
   - Add `/api/live/quick`, `/api/live/{jid}/pause`, `/api/live/{jid}/resume`, `/api/live/{jid}/state`, `/api/system/preflight`.
   - Enhance frontend cards with state pills, pause/resume buttons, genre, reconnect count, and disk space monitor.

7. `scripts/windows/`:
   - Provide `setup.ps1` / `setup.bat`, `start.ps1` / `start.bat`, `stop.ps1` / `stop.bat`.
   - Implement Windows idle sleep prevention via Win32 `SetThreadExecutionState`.

==================================================
3. TEST & VERIFICATION DISCIPLINE
==================================================

1. Execute test suite:
   ```bash
   python tests/test_rea_pipeline.py -v
   ```
   Ensure all 23 unit and integration tests pass without failures.
2. Label non-Windows host environments honestly: do not claim Windows execution verification unless executed on a Windows machine.
3. Preserve all copyright notices (MIT License, ClipPulse authors).
```
