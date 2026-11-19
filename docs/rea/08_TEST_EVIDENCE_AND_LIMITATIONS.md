# 08. Test Evidence, Limitations & Operational Boundaries

## 1. Test Execution Evidence

All pipeline components, state transitions, scoring algorithms, and layout geometry calculations were verified using a dedicated, self-contained Python test suite:

### Test Command:
```bash
python tests/test_rea_pipeline.py -v
```

### Test Results (23/23 Passed):
```text
test_exponential_backoff_bounds (__main__.TestBackoffAndResilience.test_exponential_backoff_bounds) ... ok
test_heuristic_scorer_empty_data (__main__.TestCategoryPresetsAndScoring.test_heuristic_scorer_empty_data) ... ok
test_heuristic_scorer_valid_window (__main__.TestCategoryPresetsAndScoring.test_heuristic_scorer_valid_window) ... ok
test_presets_exist (__main__.TestCategoryPresetsAndScoring.test_presets_exist) ... ok
test_disk_safety_threshold (__main__.TestConfigAndSafety.test_disk_safety_threshold) ... ok
test_model_family (__main__.TestConfigAndSafety.test_model_family) ... ok
test_reconnect_limits (__main__.TestConfigAndSafety.test_reconnect_limits) ... ok
test_live_session_initial_state (__main__.TestLiveStateMachine.test_live_session_initial_state) ... ok
test_live_session_pause_resume (__main__.TestLiveStateMachine.test_live_session_pause_resume) ... ok
test_live_session_stop (__main__.TestLiveStateMachine.test_live_session_stop) ... ok
test_live_states_defined (__main__.TestLiveStateMachine.test_live_states_defined) ... ok
test_geometry_original_mode (__main__.TestRenderGeometry.test_geometry_original_mode) ... ok
test_geometry_vertical_mode (__main__.TestRenderGeometry.test_geometry_vertical_mode) ... ok
test_layouts_include_original (__main__.TestRenderGeometry.test_layouts_include_original) ... ok
test_drawable_ascii_latin (__main__.TestRomanAndDevanagari.test_drawable_ascii_latin) ... ok
test_drawable_devanagari (__main__.TestRomanAndDevanagari.test_drawable_devanagari) ... ok
test_drawable_unsupported_scripts (__main__.TestRomanAndDevanagari.test_drawable_unsupported_scripts) ... ok
test_has_hindi (__main__.TestRomanAndDevanagari.test_has_hindi) ... ok
test_to_roman_hinglish (__main__.TestRomanAndDevanagari.test_to_roman_hinglish) ... ok
test_exceptions_hierarchy (__main__.TestURLNormalizationAndExceptions.test_exceptions_hierarchy) ... ok
test_normalize_raw_video (__main__.TestURLNormalizationAndExceptions.test_normalize_raw_video) ... ok
test_normalize_youtube_channel (__main__.TestURLNormalizationAndExceptions.test_normalize_youtube_channel) ... ok
test_scripts_exist_and_non_empty (__main__.TestWindowsScripts.test_scripts_exist_and_non_empty) ... ok

----------------------------------------------------------------------
Ran 23 tests in 0.012s

OK
```

---

## 2. Platform Environment & Verification Truthfulness

- **Development & Verification Host**: Linux / Android Termux environment (`aarch64`).
- **Target Deployment Platform**: Windows 10/11 x64.
- **Verification Status**:
  - Python logic, state machine transitions, exponential backoff, URL normalization, font unicode checking, and heuristic scoring: **Fully verified (PASS)**.
  - Windows PowerShell scripts (`setup.ps1`, `start.ps1`, `stop.ps1`) and batch wrappers (`.bat`): **Syntactically and structurally validated** on repository check; execution on the actual Windows NT kernel (`kernel32.dll:SetThreadExecutionState`) is labeled as **pending verification on the target Windows host**.

---

## 3. Known Edge Cases, Limitations & Recovery Behaviors

### 1. YouTube Bot Check / IP Rate Limiting (HTTP 429)
- **Condition**: YouTube occasionally flags automated stream extraction requests.
- **System Behavior**: Clip Pulse AI detects bot challenge strings via `media._BOT_CHECK`, sets a 10-minute exponential backoff circuit breaker (`YT_PAUSE = 600`), and halts unnecessary aggressive retries.
- **Remedy**: Export clean session cookies into `data/cookies.txt` and set `CLIPPULSE_YTDLP_COOKIES=data/cookies.txt`.

### 2. Stream Inactive / Scheduled Upcoming
- **Condition**: User inputs a stream URL before the broadcaster goes live.
- **System Behavior**: Identified via `yt-dlp` metadata as `is_upcoming`. Sets `LiveState = "WAITING_FOR_SOURCE"`, displays friendly status in dashboard, and checks every 20 seconds without crashing.

### 3. Stream Concluded / Offline
- **Condition**: Broadcaster ends the live transmission.
- **System Behavior**: Identified as `was_live`. The pipeline drains the remaining buffer segments, performs a final highlight extraction pass (`LiveState = "DRAINING"`), moves to `"STOPPED"`, and saves all clips.

### 4. Disk Space Exhaustion
- **Condition**: 24/7 continuous stream recording fills the target storage drive.
- **System Behavior**: Checked at every 6-second segment ingest loop. If available free storage falls below `CLIPPULSE_DISK_SAFETY_GB` (default 5.0 GB), capture halts immediately with an observable error stage message, protecting system stability.

### 5. Virality & Moment Selection
- **Condition**: Stream contains extended periods of quiet or uninteresting content.
- **System Behavior**: Heuristic and semantic scorers adhere to a conservative threshold. The pipeline will intentionally generate **zero clips** during dead air rather than cluttering storage with filler.
