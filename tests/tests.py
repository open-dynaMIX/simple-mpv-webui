# -*- coding: utf-8 -*-

import pytest
import requests
from requests.auth import HTTPBasicAuth


def get_uri(suffix, v=None, port=8080):
    host = "localhost"
    if v == 4:
        host = "127.0.0.1"
    elif v == 6:
        host = "[::1]"
    return f"http://{host}:{port}/{suffix}"


def get_status():
    resp = requests.get(get_uri("api/status"))
    assert resp.status_code == 200
    return resp.json()


def is_responding(uri):
    works = True
    try:
        requests.get(uri)
    except requests.exceptions.ConnectionError:
        works = False
    return works


def test_status(mpv_instance, snapshot):
    status = get_status()
    snapshot.assert_match(status)


class TestsRequests:
    """
    Wrapper class for sharing the same MPV instance fixture.
    """

    @staticmethod
    @pytest.mark.parametrize(
        "uri,status_code,content_type",
        [
            ("", 200, "text/html; charset=UTF-8"),
            ("webui.js", 200, "application/javascript; charset=UTF-8"),
            ("webui.css", 200, "text/css; charset=UTF-8"),
            ("favicon.ico", 200, "image/x-icon"),
            (
                "static/favicons/browserconfig.xml",
                200,
                "application/xml; charset=UTF-8",
            ),
            (
                "static/fontawesome-free-5.0.2/css/fontawesome-all.min.css",
                200,
                "text/css; charset=UTF-8",
            ),
            ("static/audio/silence.mp3", 200, "audio/mpeg"),
            (
                "static/fontawesome-free-5.0.2/webfonts/fa-solid-900.woff2",
                200,
                "font/woff2; charset=UTF-8",
            ),
            ("nothing_here", 404, None),
        ],
    )
    def test_static(mpv_instance, uri, status_code, content_type):
        resp = requests.get(get_uri(uri))
        assert resp.status_code == status_code
        if status_code != 200:
            return

        resp.headers.pop("Content-Length")
        assert dict(resp.headers) == {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": content_type,
            "Server": "simple-mpv-webui",
            "Connection": "close",
        }

    @staticmethod
    @pytest.mark.parametrize(
        "endpoint,arg,key,value,invert_actual",
        [
            ("play", "", "pause", False, False),
            ("pause", "", "pause", True, False),
            ("toggle_pause", "", "pause", False, True),
            ("fullscreen", "", "fullscreen", True, True),
            ("loop_file", "no", "loop-file", False, False),
            ("loop_file", "inf", "loop-file", True, False),
            ("loop_playlist", "no", "loop-playlist", False, False),
            ("loop_playlist", "inf", "loop-playlist", "inf", False),
            # Thats a quirk from mpv. For `loop-file` it returns True, for `loop-playlist` it returns `"inf"`
            ("add_volume", "10", "volume", 10, False),
            ("set_volume", "100", "volume", 100, False),
            ("add_sub_delay", "0.1", "sub-delay", 100, False),
            ("set_sub_delay", "1", "sub-delay", 1000, False),
            ("add_audio_delay", "-0.1", "audio-delay", -100, False),
            ("set_audio_delay", "-1", "audio-delay", -1000, False),
        ],
    )
    def test_post(mpv_instance, endpoint, arg, key, value, invert_actual):
        if invert_actual:
            status = get_status()
            value = not status[key]

        if endpoint in ["add_volume", "add_sub_delay", "add_audio_delay"]:
            status = get_status()
            value = status[key] + value

        resp = requests.post(get_uri(f"api/{endpoint}/{arg}"))
        assert resp.status_code == 200

        status = get_status()
        assert status[key] == value

    @staticmethod
    @pytest.mark.parametrize(
        "endpoint,arg,position", [("seek", "1", 1.008979), ("set_position", "2", 2.0)],
    )
    def test_seek(mpv_instance, endpoint, arg, position):
        # reset position
        requests.post(get_uri(f"api/pause"))
        requests.post(get_uri(f"api/set_position/0"))

        resp = requests.post(get_uri(f"api/{endpoint}/{arg}"))
        assert resp.status_code == 200

        status = get_status()
        assert status["position"] == position

    @staticmethod
    def test_playlist(mpv_instance):
        def get_order(s):
            return [
                file["filename"].split("/")[-1].replace(" - dummy.mp3", "")
                for file in s["playlist"]
            ]

        # make sure we're on the
        requests.post(get_uri(f"api/pause"))
        requests.post(get_uri("api/playlist_jump/0"))

        status = get_status()
        assert status["playlist"][0]["current"] is True
        assert len(status["playlist"]) == 3
        assert get_order(status) == ["01", "02", "03"]

        resp = requests.post(get_uri("api/playlist_jump/1"))
        assert resp.status_code == 200
        status = get_status()
        assert status["playlist"][1]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        resp = requests.post(get_uri("api/playlist_next"))
        assert resp.status_code == 200
        status = get_status()
        assert status["playlist"][2]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        resp = requests.post(get_uri("api/playlist_prev"))
        assert resp.status_code == 200
        status = get_status()
        assert status["playlist"][1]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        resp = requests.post(get_uri("api/playlist_move/0/3"))
        assert resp.status_code == 200
        status = get_status()
        assert get_order(status) == ["02", "03", "01"]

        resp = requests.post(get_uri("api/playlist_move_up/1"))
        assert resp.status_code == 200
        status = get_status()
        assert get_order(status) == ["03", "02", "01"]

        # brute forcing shuffle :rolling_eyes:
        success = False
        order = None
        for _ in range(5):
            resp = requests.post(get_uri("api/playlist_shuffle"))
            assert resp.status_code == 200
            order = get_order(get_status())
            if not order == ["03", "02", "01"]:
                success = True
                break
        assert success, "playlist_shuffle failed!"

        # make sure we're not removing the current playlist entry
        requests.post(get_uri("api/playlist_jump/0"))
        resp = requests.post(get_uri("api/playlist_remove/2"))
        assert resp.status_code == 200
        status = get_status()
        assert len(status["playlist"]) == 2
        assert get_order(status) == order[:2]


@pytest.mark.parametrize(
    "mpv_instance,expected_devices",
    [
        ({}, ["auto", "alsa", "jack", "sdl", "sndio"]),
        (
            {"options": ['--script-opts=webui-audio_devices="auto jack sndio"']},
            ["auto", "jack", "sndio"],
        ),
    ],
    indirect=["mpv_instance"],
)
def test_audio_device_cycling(mpv_instance, expected_devices):
    status = get_status()
    assert len(status["audio-devices"]) == len(expected_devices)

    for expexted_device in expected_devices:

        for device in status["audio-devices"]:
            assert device["active"] == (device["name"] == expexted_device)
        resp = requests.post(get_uri("api/cycle_audio_device"))
        assert resp.status_code == 200
        status = get_status()


@pytest.mark.parametrize(
    "mpv_instance",
    [{"files": ["./environment/test_media/dummy.mp4"]}],
    indirect=["mpv_instance"],
)
@pytest.mark.parametrize(
    "endpoint,track_type", [("cycle_audio", "audio"), ("cycle_sub", "sub")]
)
def test_cycle_tracks(mpv_instance, endpoint, track_type):
    status = get_status()
    for track in status["track-list"]:
        if track["type"] == track_type:
            assert track["selected"] is True

    resp = requests.post(get_uri(f"api/{endpoint}"))
    assert resp.status_code == 200

    status = get_status()
    for track in status["track-list"]:
        if track["type"] == track_type:
            assert track["selected"] is False

    resp = requests.post(get_uri(f"api/{endpoint}"))
    assert resp.status_code == 200

    status = get_status()
    for track in status["track-list"]:
        if track["type"] == track_type:
            assert track["selected"] is True


@pytest.mark.parametrize(
    "mpv_instance,v4_works,v6_works",
    [
        ({}, True, True),
        ({"options": ["--script-opts=webui-ipv4=no"]}, False, True),
        ({"options": ["--script-opts=webui-ipv6=no"]}, True, False),
        ({"options": ["--script-opts=webui-disable=yes"]}, False, False),
    ],
    indirect=["mpv_instance"],
)
def test_disablers(mpv_instance, v4_works, v6_works):
    uri = get_uri("api/status", v=4)
    assert is_responding(uri) == v4_works
    uri = get_uri("api/status", v=6)
    assert is_responding(uri) == v6_works


@pytest.mark.parametrize(
    "credentials,status_code",
    [(None, 401), (("user", "wrong"), 401), (("user", "secret"), 200)],
)
def test_auth(htpasswd, mpv_instance, credentials, status_code):
    auth = None
    if credentials:
        auth = HTTPBasicAuth(*credentials)
    resp = requests.get(get_uri("api/status"), auth=auth)
    assert resp.status_code == status_code


@pytest.mark.parametrize(
    "mpv_instance,expected_8080,expected_8000",
    [({}, True, False), ({"options": ["--script-opts=webui-port=8000"]}, False, True)],
    indirect=["mpv_instance"],
)
@pytest.mark.parametrize("v", [4, 6])
def test_port(mpv_instance, v, expected_8080, expected_8000):
    uri = get_uri("api/status", v=v, port=8080)
    assert is_responding(uri) == expected_8080

    uri = get_uri("api/status", v=v, port=8000)
    assert is_responding(uri) == expected_8000


@pytest.mark.parametrize(
    "mpv_instance",
    [{"options": ["--script-opts=webui-logging=yes"]}],
    indirect=["mpv_instance"],
)
def test_logging(mpv_instance):
    resp = requests.get(get_uri("api/status"), headers={"Referer": "https://referer"})
    assert resp.status_code == 200

    # example log line
    # ::1 - - [17/Apr/2020:13:18:22 +0000] "GET /api/status HTTP/1.1" 200 1253 "https://referer" "python-requests/2.23.0"

    assert (
        mpv_instance.expect(
            r"\[webui\] ::1 - - \[\d\d?/[A-Z][a-z][a-z][a-z]?/?/\d{4}:\d{2}:\d{2}:\d{2} \+0{4}\] "
            r'"GET /api/status HTTP/1.1" 200 \d* "https://referer" "python-requests/',
            timeout=1,
        )
        == 0
    )
