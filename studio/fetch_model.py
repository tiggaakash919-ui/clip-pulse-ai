"""The speech-to-text model: downloaded once, by itself, the first time it is needed.

Nothing has to be run by hand. (python -m studio.fetch_model still works, for getting it ahead of time.) It is
about 480 MB. It is unpacked next to where it will live and moved into place only when it is whole, so a download
that was cut off can never leave half a model behind."""
import shutil
import tarfile
import threading
import urllib.request

from . import config

URL = f"https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/{config.ASR_MODEL_NAME}.tar.bz2"
_lock = threading.Lock()
state = {"doing": False, "percent": 0, "error": ""}


def is_whisper() -> bool:
    return getattr(config, "ASR_MODEL_FAMILY", "whisper") == "whisper" or "whisper" in config.ASR_MODEL_NAME.lower()


def ready() -> bool:
    """Is the whole model there: the word list and required ONNX parts?"""
    d = config.ASR_MODEL_DIR
    if not d.is_dir():
        return False
    has_tokens = (d / "tokens.txt").is_file() or any(d.glob("*tokens*.txt"))
    if not has_tokens:
        return False
    if is_whisper():
        return any(d.glob("*encoder*.onnx")) and any(d.glob("*decoder*.onnx"))
    return all(any(d.glob(f"{part}*.onnx")) for part in ("encoder", "decoder", "joiner"))


def _progress(blocks, size, total):
    if total > 0:
        state["percent"] = min(99, int(blocks * size * 100 / total))


def ensure() -> None:
    """Make sure the model is on this computer, downloading it if it is not. One download at a time: anything else
    that needs the model meanwhile waits for it here."""
    if ready():
        return
    with _lock:
        if ready():
            return
        state.update(doing=True, percent=0, error="")
        kind = "Multilingual Whisper" if is_whisper() else "Parakeet"
        print(f"\n  Downloading the speech model ({kind}, model {config.ASR_MODEL_NAME})...\n", flush=True)
        config.MODELS_DIR.mkdir(parents=True, exist_ok=True)
        tmp, part = config.MODELS_DIR / "speech-model.tar.bz2", config.MODELS_DIR / "speech-model.unpacking"
        try:
            urllib.request.urlretrieve(URL, tmp, _progress)
            shutil.rmtree(part, ignore_errors=True)
            part.mkdir()
            with tarfile.open(tmp, "r:bz2") as t:
                for m in t.getmembers():  # only plain files and folders that stay inside the unpacking folder
                    if (m.isfile() or m.isdir()) and not m.name.startswith(("/", "..")) and ".." not in m.name.split("/"):
                        t.extract(m, part)
            got = part / config.ASR_MODEL_NAME
            if not got.is_dir():
                # Some tar archives extract without a top-level dir or slightly different name
                subdirs = [p for p in part.iterdir() if p.is_dir()]
                if len(subdirs) == 1:
                    got = subdirs[0]
                else:
                    got = part
            shutil.rmtree(config.ASR_MODEL_DIR, ignore_errors=True)        # a half-finished one from before
            shutil.move(str(got), str(config.ASR_MODEL_DIR))
            print("  Speech model ready.\n", flush=True)
        except Exception as e:  # noqa: BLE001
            state["error"] = str(e)[-200:]
            raise RuntimeError(f"PeakCut couldn't download its speech model ({config.ASR_MODEL_NAME}). Check the "
                               "internet connection and free disk space, then try again.") from e
        finally:
            state["doing"] = False
            tmp.unlink(missing_ok=True)
            shutil.rmtree(part, ignore_errors=True)


def main():
    if ready():
        print("Speech model already present.")
        return
    ensure()


if __name__ == "__main__":
    main()
