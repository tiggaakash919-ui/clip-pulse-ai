import math
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))


class FakeArray(list):
    def max(self):
        return max(self) if len(self) else 0.0

    def std(self):
        if not self:
            return 1.0
        avg = sum(self) / len(self)
        var = sum((v - avg) ** 2 for v in self) / len(self)
        return (var ** 0.5) or 1.0

    def __sub__(self, other):
        if isinstance(other, (int, float)):
            return FakeArray([x - other for x in self])
        return FakeArray([a - b for a, b in zip(self, other)])

    def __truediv__(self, other):
        return FakeArray([x / other for x in self])

    def __getitem__(self, item):
        res = super().__getitem__(item)
        return FakeArray(res) if isinstance(item, slice) else res


class FakeNumpy:
    def zeros(self, n):
        return FakeArray([0.0] * n)

    def array(self, x):
        return FakeArray(x)

    def asarray(self, x, dtype=None):
        return FakeArray(x)

    def median(self, x):
        s = sorted(x)
        return s[len(s) // 2] if s else 0.0

    def std(self, x):
        if not x:
            return 1.0
        avg = sum(x) / len(x)
        var = sum((v - avg) ** 2 for v in x) / len(x)
        return (var ** 0.5) or 1.0

    def max(self, x):
        return max(x) if len(x) else 0.0

    def ceil(self, x):
        return math.ceil(x)

FakeNumpy.ndarray = FakeArray

try:
    import numpy as _np
except ImportError:
    sys.modules["numpy"] = FakeNumpy()

# Pre-mock other heavy native modules before studio imports
for mod in [
    "soundfile",
    "sqlalchemy",
    "sqlalchemy.sql",
    "sqlalchemy.engine",
    "sherpa_onnx",
    "httpx",
    "PIL",
    "PIL.Image",
    "PIL.ImageDraw",
    "PIL.ImageFont",
    "yt_dlp",
]:
    if mod not in sys.modules:
        sys.modules[mod] = MagicMock()

from studio import brain, config, live, render, roman


class TestLiveStateMachine(unittest.TestCase):
    def test_live_states_defined(self):
        expected = {
            "IDLE",
            "VALIDATING",
            "WAITING_FOR_SOURCE",
            "RECORDING",
            "RECONNECTING",
            "PAUSED",
            "DRAINING",
            "STOPPED",
            "ERROR",
        }
        self.assertEqual(live.LIVE_STATES, expected)

    def test_live_session_initial_state(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            job = {"id": "test_job_1", "dir": tmp_dir, "source": {"url": "https://youtube.com/watch?v=dummy"}}
            session = live.Session(job, {})
            self.assertEqual(session.state, "IDLE")
            self.assertFalse(session.is_paused)
            self.assertEqual(session.reconnect_count, 0)

    def test_live_session_pause_resume(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            job = {"id": "test_job_2", "dir": tmp_dir, "source": {"url": "https://youtube.com/watch?v=dummy"}}
            session = live.Session(job, {})

            session.pause()
            self.assertTrue(session.is_paused)
            self.assertEqual(session.state, "PAUSED")
            self.assertEqual(session.job.get("live_state"), "PAUSED")

            session.resume()
            self.assertFalse(session.is_paused)
            self.assertEqual(session.state, "RECORDING")
            self.assertEqual(session.job.get("live_state"), "RECORDING")

    def test_live_session_stop(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            job = {"id": "test_job_3", "dir": tmp_dir, "source": {"url": "https://youtube.com/watch?v=dummy"}}
            session = live.Session(job, {})

            session.stop("Test manual stop")
            self.assertTrue(session.user_stopped)
            self.assertTrue(session.stop_flag.is_set())
            self.assertEqual(session.state, "STOPPED")
            self.assertEqual(session.job.get("status"), "done")
            self.assertEqual(session.job.get("stage"), "Test manual stop")


class TestBackoffAndResilience(unittest.TestCase):
    def test_exponential_backoff_bounds(self):
        max_delay = config.RECONNECT_MAX_DELAY
        for fails in range(1, 20):
            # Same formula as in live._ingest
            jitter = 1.0  # simulate mid jitter
            delay = min(max_delay, (2 ** min(fails, 5)) + jitter)
            self.assertGreaterEqual(delay, 2.0)
            self.assertLessEqual(delay, max_delay)


class TestURLNormalizationAndExceptions(unittest.TestCase):
    def test_normalize_youtube_channel(self):
        url = "https://www.youtube.com/@SomeCreator"
        self.assertEqual(live.normalize(url), "https://www.youtube.com/@SomeCreator/live")

    def test_normalize_raw_video(self):
        url = "https://www.youtube.com/watch?v=abc123xyz"
        self.assertEqual(live.normalize(url), url)

    def test_exceptions_hierarchy(self):
        self.assertTrue(issubclass(live.StreamUpcoming, live.NotLive))
        self.assertTrue(issubclass(live.StreamEnded, live.NotLive))


class TestRomanAndDevanagari(unittest.TestCase):
    def test_drawable_ascii_latin(self):
        self.assertTrue(roman.drawable("Hello World 123!"))

    def test_drawable_devanagari(self):
        # With allow_devanagari=True (default), Hindi text is permitted
        self.assertTrue(roman.drawable("नमस्ते भारत", allow_devanagari=True))
        # With allow_devanagari=False, Hindi text is rejected
        self.assertFalse(roman.drawable("नमस्ते भारत", allow_devanagari=False))

    def test_drawable_unsupported_scripts(self):
        # Cyrillic should be rejected by Poppins caption drawer
        self.assertFalse(roman.drawable("Привет"))

    def test_to_roman_hinglish(self):
        # Converts Hindi script to phonetic Latin chat spelling
        res = roman.to_roman("नमस्ते")
        self.assertTrue(len(res) > 0)
        self.assertTrue(all(ord(c) < 128 for c in res))

    def test_has_hindi(self):
        self.assertTrue(roman.has_hindi("क्या चल रहा है"))
        self.assertFalse(roman.has_hindi("what is going on"))


class TestCategoryPresetsAndScoring(unittest.TestCase):
    def test_presets_exist(self):
        for category in ["gaming", "podcast", "irl", "general"]:
            self.assertIn(category, brain.CATEGORY_PRESETS)
            desc = brain.category_focus(category)
            self.assertTrue(len(desc) > 10)

    def test_heuristic_scorer_empty_data(self):
        # Empty signals should produce empty clips safely
        clips = brain.heuristic_highlight_scorer([], [], n=5, max_len=60, duration=100.0, category="general")
        self.assertEqual(clips, [])

    def test_heuristic_scorer_valid_window(self):
        # Generate simulated words spanning 50 seconds
        words = []
        for i in range(100):
            t = 5.0 + (i * 0.4)
            w = f"word{i}"
            if i in (20, 50, 75, 99):
                w += "."  # sentence boundaries
            words.append({"w": w, "s": t, "e": t + 0.35})

        # Generate simulated loudness points with a high energy peak
        loudness = []
        for i in range(60):
            t = float(i)
            # simulate audio spike between t=15 and t=35
            val = 30.0 if 15 <= t <= 35 else 5.0
            loudness.append(val)

        clips = brain.heuristic_highlight_scorer(loudness, words, n=3, max_len=60, duration=60.0, category="gaming")
        self.assertIsInstance(clips, list)
        for clip in clips:
            self.assertIn("start", clip)
            self.assertIn("end", clip)
            self.assertIn("score", clip)
            self.assertIn("hook", clip)
            self.assertIn("signals", clip)
            self.assertTrue(clip.get("degraded_mode"))
            duration = clip["end"] - clip["start"]
            self.assertGreaterEqual(duration, 14.0)
            self.assertLessEqual(duration, 60.0)


class TestRenderGeometry(unittest.TestCase):
    def test_layouts_include_original(self):
        self.assertIn("original", render.LAYOUTS)
        self.assertIn("blur", render.LAYOUTS)
        self.assertIn("zoom", render.LAYOUTS)
        self.assertIn("crop", render.LAYOUTS)

    def test_geometry_original_mode(self):
        layout_name, fg_h, hook_y, cap_y = render.geometry(1920, 1080, layout="original")
        self.assertEqual(layout_name, "original")
        self.assertEqual(fg_h, 1080)
        self.assertGreater(hook_y, 0)
        self.assertGreater(cap_y, hook_y)

    def test_geometry_vertical_mode(self):
        layout_name, fg_h, hook_y, cap_y = render.geometry(1920, 1080, layout="blur")
        self.assertEqual(layout_name, "blur")
        self.assertGreater(fg_h, 0)
        self.assertGreater(hook_y, 0)
        self.assertGreater(cap_y, hook_y)


class TestConfigAndSafety(unittest.TestCase):
    def test_disk_safety_threshold(self):
        self.assertGreaterEqual(config.DISK_SAFETY_GB, 1.0)

    def test_reconnect_limits(self):
        self.assertGreaterEqual(config.RECONNECT_MAX_TRIES, 5)
        self.assertGreaterEqual(config.RECONNECT_MAX_DELAY, 10.0)

    def test_model_family(self):
        self.assertIn(config.ASR_MODEL_FAMILY, ("whisper", "transducer"))


class TestWindowsScripts(unittest.TestCase):
    def test_scripts_exist_and_non_empty(self):
        scripts_dir = REPO_ROOT / "scripts" / "windows"
        expected = [
            "setup.ps1",
            "setup.bat",
            "start.ps1",
            "start.bat",
            "stop.ps1",
            "stop.bat",
        ]
        for name in expected:
            file_path = scripts_dir / name
            self.assertTrue(file_path.exists(), f"Missing script: {name}")
            self.assertGreater(file_path.stat().st_size, 20, f"Empty script: {name}")


class TestTermuxScripts(unittest.TestCase):
    def test_termux_scripts_exist(self):
        termux_dir = REPO_ROOT / "scripts" / "termux"
        expected = ["setup.sh", "start.sh", "stop.sh"]
        for name in expected:
            file_path = termux_dir / name
            self.assertTrue(file_path.exists(), f"Missing Termux script: {name}")
            self.assertGreater(file_path.stat().st_size, 20, f"Empty Termux script: {name}")


class TestAndroidApp(unittest.TestCase):
    def test_build_apk_script_exists(self):
        script = REPO_ROOT / "scripts" / "build_apk.sh"
        self.assertTrue(script.exists())

    def test_built_apk_exists_and_valid(self):
        apk_path = REPO_ROOT / "data" / "PeakCut.apk"
        self.assertTrue(apk_path.exists())
        self.assertGreater(apk_path.stat().st_size, 10000)


class TestBugFixes(unittest.TestCase):
    def test_find_clips_with_callable_as_category(self):
        # Ensure passing a callable (e.g. notes.append) as the 9th positional argument does NOT crash with AttributeError
        notes = []
        words = [{"w": "hello", "s": 0.0, "e": 1.0}, {"w": "world.", "s": 1.0, "e": 2.0}]
        db = [10.0, 12.0]
        try:
            # Pass notes.append as 9th positional argument
            clips, ai = brain.find_clips(words, db, 2.0, "Title", "Uploader", 2, 1, 2, notes.append)
            self.assertIsInstance(clips, list)
        except AttributeError as e:
            self.fail(f"find_clips raised AttributeError: {e}")

    def test_safe_friendly_unexpected_end_of_data(self):
        from studio import safe
        err = "UnicodeDecodeError: 'utf-8' codec can't decode bytes in position 1-2: unexpected end of data"
        friendly_msg = safe.friendly(err)
        self.assertIn("interrupted", friendly_msg.lower())


if __name__ == "__main__":
    unittest.main()

