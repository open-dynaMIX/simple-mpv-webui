# -*- coding: utf-8 -*-
# snapshottest: v1 - https://goo.gl/zC4yUc
from __future__ import unicode_literals

from snapshottest import Snapshot

snapshots = Snapshot()

snapshots["test_status 1"] = {
    "audio-delay": 0,
    "audio-devices": [
        {"active": True, "description": "Autoselect device", "name": "auto"},
        {"active": False, "description": "Default (alsa)", "name": "alsa"},
        {"active": False, "description": "Default (jack)", "name": "jack"},
        {"active": False, "description": "Default (sdl)", "name": "sdl"},
        {"active": False, "description": "Default (sndio)", "name": "sndio"},
    ],
    "chapter": 0,
    "chapters": 0,
    "chapter-list": [],
    "duration": 6.024,
    "filename": "01 - dummy.mp3",
    "fullscreen": False,
    "loop-file": False,
    "loop-playlist": False,
    "metadata": {
        "album": "Dummy Album",
        "artist": "Dummy Artist",
        "comment": "0",
        "date": "2020",
        "encoder": "Lavc57.10",
        "genre": "Jazz",
        "title": "First dummy",
    },
    "pause": True,
    "playlist": [
        {
            "current": True,
            "filename": "./environment/test_media/01 - dummy.mp3",
            "playing": True,
        },
        {"filename": "./environment/test_media/02 - dummy.mp3"},
        {"filename": "./environment/test_media/03 - dummy.mp3"},
    ],
    "position": -0.0,
    "remaining": 6.024,
    "speed": 1,
    "sub-delay": 0,
    "track-list": [
        {
            "albumart": False,
            "audio-channels": 2,
            "codec": "mp3",
            "decoder-desc": "mp3float (MP3 (MPEG audio layer 3))",
            "default": False,
            "demux-channel-count": 2,
            "demux-channels": "stereo",
            "demux-samplerate": 48000,
            "dependent": False,
            "external": False,
            "ff-index": 0,
            "forced": False,
            "id": 1,
            "selected": True,
            "src-id": 0,
            "type": "audio",
        }
    ],
    "webui-version": "2.1.0",
    "volume": 0,
    "volume-max": 130,
}
