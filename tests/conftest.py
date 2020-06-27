# -*- coding: utf-8 -*-

import glob
from pathlib import Path

import pexpect
import pytest


@pytest.fixture(scope="class")
def mpv_instance(request):
    params = getattr(request, "param", {})
    files = params.get(
        "files", sorted(glob.glob("./environment/test_media/* - dummy.mp3"))
    )
    options = params.get("options", [])

    process = pexpect.spawn("mpv", ["--config-dir=./environment/", *options, *files])

    # uncomment for printing mpv output to stdout
    # import sys
    # process.logfile = sys.stdout.buffer

    process.expect(r"\(Paused\) A?V?: -?00:00:00", timeout=5)

    yield process

    process.terminate(force=True)

    # TODO: Determine if a test failed in the current scope instead of the whole session
    if request.session.testsfailed > 0:
        # TODO: This doesn't really work. Output is truncated.
        print("MPV output:")
        process.stdout.seek(0)
        print(process.read().decode())


@pytest.fixture(scope="class")
def htpasswd():
    file = Path("/tmp/.htpasswd")
    file.open("w").write("user:secret")

    yield file

    file.unlink()
