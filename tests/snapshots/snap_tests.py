# -*- coding: utf-8 -*-
# snapshottest: v1 - https://goo.gl/zC4yUc
from __future__ import unicode_literals

from snapshottest import Snapshot

snapshots = Snapshot()

snapshots["TestsRequests.test_post_wrong_args[add-&-foo] 1"] = {
    "message": "Parameter name contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[add-foo-&] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[add_audio_delay-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[add_chapter-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[add_sub_delay-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[add_volume-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[cycle-&-foo] 1"] = {
    "message": "Parameter name contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[cycle-foo-&] 1"] = {
    "message": 'Cycle paramater is not "up" or "down"'
}

snapshots["TestsRequests.test_post_wrong_args[loadfile-None-None] 1"] = {
    "message": "No url provided!"
}

snapshots["TestsRequests.test_post_wrong_args[loadfile-http://foo-invalid] 1"] = {
    "message": "Invalid mode: 'foo'"
}

snapshots["TestsRequests.test_post_wrong_args[loop_file-&-None] 1"] = {
    "message": "Invalid parameter!"
}

snapshots["TestsRequests.test_post_wrong_args[loop_file-None-None] 1"] = {
    "message": "Invalid parameter!"
}

snapshots["TestsRequests.test_post_wrong_args[loop_playlist-&-None] 1"] = {
    "message": "Invalid parameter!"
}

snapshots["TestsRequests.test_post_wrong_args[multiply-&-23] 1"] = {
    "message": "Parameter name contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[multiply-23-&] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[multiply-23-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_jump-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_jump-None-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_move-&-23] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_move-23-&] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_move-23-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_move_up-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_move_up-None-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_remove-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[playlist_remove-None-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[seek-None-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[seek-g-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[set-&-foo] 1"] = {
    "message": "Parameter name contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[set-foo- ] 1"] = {
    "message": "Parameter value contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[set_audio_delay-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[set_position-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[set_position-None-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[set_sub_delay-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[set_volume-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[speed_adjust-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[speed_set-&-None] 1"] = {
    "message": "Parameter needs to be an integer or float"
}

snapshots["TestsRequests.test_post_wrong_args[toggle-&-None] 1"] = {
    "message": "Parameter name contains invalid characters"
}

snapshots["TestsRequests.test_post_wrong_args[toggle-None-None] 1"] = {
    "message": "Parameter name contains invalid characters"
}

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
    "chapter-list": [],
    "chapters": 0,
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
            "demux-bitrate": 32000,
            "demux-channel-count": 2,
            "demux-channels": "stereo",
            "demux-samplerate": 48000,
            "dependent": False,
            "external": False,
            "ff-index": 0,
            "forced": False,
            "hearing-impaired": False,
            "id": 1,
            "selected": True,
            "type": "audio",
            "visual-impaired": False,
        }
    ],
    "volume": 0,
    "volume-max": 130,
    "webui-version": "2.2.0",
}
