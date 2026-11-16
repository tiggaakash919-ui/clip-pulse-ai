"""Small helpers for what is safe to show a user."""
import re

_PATH = re.compile(r"(?:[A-Za-z]:)?[\\/][^\s'\"]*[\\/][^\s'\"]+")


def friendly(e, limit=600) -> str:
    """An error message for the user: trimmed, with any server file paths removed. A missing ffmpeg, which Windows
    reports only as "the system cannot find the file specified", is said in plain words with what to do."""
    from . import tools
    exp = tools.explain(e)
    if exp:
        return exp
    msg = str(e)
    if "unexpected end of data" in msg or "codec can't decode" in msg:
        return "Connection to YouTube was interrupted while downloading stream data. Please retry."
    return _PATH.sub("[file]", msg[-limit:])

