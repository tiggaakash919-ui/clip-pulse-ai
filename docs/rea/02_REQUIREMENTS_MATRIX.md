# 02. Requirements Verification Matrix

Classification Key:
- **A**: Implemented and unit/pipeline-tested.
- **B**: Implemented and tested in Linux/Termux, pending execution on Windows target host.
- **C**: Partially implemented.
- **D**: Missing / Not implemented.
- **E**: Blocked by external API credentials, client permissions, or platform restrictions.

---

| Requirement | Status | Implementation Details & Code References | Notes & Caveats |
|---|---|---|---|
| **1. Single Authorized YouTube Livestream URL Ingest** | **A** | `studio/live.py:normalize()`, `resolve()`, `quick_live()`, `studio/server.py:POST /api/live/quick` | Supports channel URLs (`/@channel`) and direct watch URLs (`/watch?v=`). |
| **2. Bounded Crash-Tolerant Rolling Buffer** | **A** | `studio/live.py:Session._ingest()`, `Session._cleanup_old()` | Rolling buffer retains 20 minutes in 6s segments (`buf/seg_*.ts`). |
| **3. Observable State Machine & Pause/Resume/Stop** | **A** | `studio/live.py:LIVE_STATES`, `set_state()`, `pause()`, `resume()`, `stop()`, `studio/server.py` | States: `IDLE`, `VALIDATING`, `WAITING_FOR_SOURCE`, `RECORDING`, `RECONNECTING`, `PAUSED`, `DRAINING`, `STOPPED`, `ERROR`. Tested in `tests/test_rea_pipeline.py`. |
| **4. Exponential Reconnect Backoff with Jitter** | **A** | `studio/live.py:Session._ingest()`, `config.RECONNECT_MAX_TRIES`, `config.RECONNECT_MAX_DELAY` | Formula: `min(60, 2**min(fails, 5) + jitter)`. Distinguishes temporary network cuts from finished streams. |
| **5. Disk Space Safety Circuit Breaker** | **A** | `studio/live.py:Session._ingest()`, `config.DISK_SAFETY_GB` | Stops recording cleanly if free disk space drops below threshold (default 5.0 GB). |
| **6. Local Multilingual Transcription (Hindi, English, Hinglish)** | **B** | `studio/transcribe.py:_whisper_files()`, `sherpa-onnx.OfflineRecognizer.from_whisper()`, `studio/fetch_model.py` | Supports Whisper ONNX (base/tiny/small). Verified in code; Windows CUDA acceleration requires runtime check on target machine. |
| **7. Word-Level Timestamp Alignment** | **A** | `studio/transcribe.py:_words()` | Decodes byte-level BPE tokens (`Ġ`, ` `) and attaches `{w, s, e}` word timing. |
| **8. Explainable Highlight Scoring & Fallback** | **A** | `studio/brain.py:heuristic_highlight_scorer()`, `loud_zscore()`, `sentence_ends()` | Fallback when semantic AI is inactive. Evaluates energy z-score, speech pacing, sentence breaks. Tested in `tests/test_rea_pipeline.py`. |
| **9. Content Category Presets** | **A** | `studio/brain.py:CATEGORY_PRESETS`, `category_focus()` | Presets for `gaming`, `podcast`, `irl`, `general` adapting scoring heuristics and LLM prompts. |
| **10. Conservative 15–60s Clips & Sentence Boundary Snapping** | **A** | `studio/brain.py:_snap()`, `sentence_ends()` | Snaps to sentence punctuation (`.`, `?`, `!`, Hindi danda `।`). Tested in `tests/test_rea_pipeline.py`. |
| **11. Quality Over Quantity (Zero-Clip Tolerance)** | **A** | `studio/brain.py:heuristic_highlight_scorer()` | Dead or low-energy intervals produce zero clips rather than garbage filler. |
| **12. Framing Modes: 9:16 Vertical & Original Aspect Ratio** | **A** | `studio/render.py:geometry()`, `LAYOUTS`, `_filter()` | Supports `blur`, `zoom`, `crop`, and native source aspect ratio `original`. Tested in `tests/test_rea_pipeline.py`. |
| **13. Devanagari & Latin Caption Rendering** | **A** | `studio/roman.py:drawable()`, `studio/render.py:build_ass()` | Bundled Poppins-ExtraBold OFL font with full Devanagari Unicode coverage. Tested in `tests/test_rea_pipeline.py`. |
| **14. Automatic Local Directory Clip Export** | **A** | `studio/render.py:render_clip()`, `config.CLIPS_EXPORT_DIR` | Rendered `.mp4` and `.jpg` automatically copied to `data/exported_clips/`. |
| **15. Windows Native Setup & Control Scripts** | **B** | `scripts/windows/setup.ps1`, `setup.bat`, `start.ps1`, `start.bat`, `stop.ps1`, `stop.bat` | Scripts created and validated for structure/syntax. Execution verification pending on Windows host. |
| **16. Windows Idle Sleep Prevention** | **B** | `scripts/windows/start.ps1:SetThreadExecutionState` | Implements Win32 `ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_AWAYMODE_REQUIRED`. Windows-specific verification pending on Windows host. |
| **17. YouTube Shorts Official Publishing** | **E** | `docs/rea/05_PUBLISHING_INTEGRATIONS_GUIDE.md` | Requires Google Cloud Project, OAuth 2.0 Client Credentials, and YouTube Data API v3 upload quota. |
| **18. Instagram Reels Official Publishing** | **E** | `docs/rea/05_PUBLISHING_INTEGRATIONS_GUIDE.md` | Requires Meta Developer App, Instagram Business/Creator Account, and Graph API Container publishing permissions. |
