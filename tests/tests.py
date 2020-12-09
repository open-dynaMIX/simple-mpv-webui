# -*- coding: utf-8 -*-

import urllib

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
    try:
        requests.get(uri)
    except requests.exceptions.ConnectionError:
        return False
    return True


def get_script_opts(options):
    option_strings = []
    for option, value in options.items():
        option_strings.append(f"webui-{option}={value}")

    return {"options": [f"--script-opts={','.join(option_strings)}"]}


def send(command, arg=None, arg2=None, expect=200, status=None):
    api = f"api/{command}"
    for a in [arg, arg2]:
        if a is not None:
            api += f"/{a}"
    resp = requests.post(get_uri(api))
    assert resp.status_code == expect
    if status is not None:
        return get_status()[status]


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

        assert send(endpoint, arg=arg, status=key) == value

    @staticmethod
    @pytest.mark.parametrize(
        "endpoint,arg,position",
        [("seek", "1", 1.008979), ("set_position", "2", 2.0)],
    )
    def test_seek(mpv_instance, endpoint, arg, position):
        # reset position
        send("pause")
        send("set_position", arg="0")

        assert send(endpoint, arg=arg, status="position") == position

    @staticmethod
    def test_speed(mpv_instance):
        # We need a dedicated test as changing the speed can mess up other tests.
        # This makes sure we run in isolation and in order.
        TESTS = (
            ("speed_set", "2.2", 2.2),
            ("speed_adjust", "1", 2.2),
            ("speed_set", "1.0", 1),
            ("speed_adjust", "1.1", 1.1),
            ("speed_adjust", "3", 3.3),
            ("speed_set", "1", 1),
            ("speed_adjust", "0.9", 0.9),
            ("speed_set", "", 1),
        )
        for (endpoint, arg, value) in TESTS:
            assert send(endpoint, arg=arg, status="speed") == value

    @staticmethod
    def test_add(mpv_instance):
        def add(arg=None):
            return send("add/volume", arg=arg, status="volume")

        send("set/volume", "10")
        assert add() == 11
        assert add("") == 12
        assert round(add("5.1"), 1) == 17.1
        assert round(add("-3"), 1) == 14.1

    @staticmethod
    def test_cycle(mpv_instance):
        def cycle(arg=None):
            return send("cycle/pause", arg=arg, status="pause")

        send("set/pause", "yes")
        assert cycle() is False
        assert cycle("") is True
        assert cycle("up") is False
        assert cycle("down") is True

    @staticmethod
    def test_multiply(mpv_instance):
        def multiply(arg):
            return send("multiply/volume", arg=arg, status="volume")

        send("set/volume", "10")
        assert multiply("2") == 20
        assert multiply("1.1") == 22

    @staticmethod
    def test_set(mpv_instance):
        def set(arg):
            return send("set/volume", arg=arg, status="volume")

        assert round(set("91.2"), 1) == 91.2
        assert round(set("107.3"), 1) == 107.3

    @staticmethod
    def test_toggle(mpv_instance):
        def toggle():
            return send("toggle/fullscreen", status="fullscreen")

        send("set/fullscreen", arg="yes")
        assert toggle() is False
        assert toggle() is True

    @staticmethod
    def test_playlist(mpv_instance):
        def get_order(s):
            return [
                file["filename"].split("/")[-1].replace(" - dummy.mp3", "")
                for file in s["playlist"]
            ]

        # make sure we're on the
        send("pause")
        send("playlist_jump", arg="0")

        status = get_status()
        assert status["playlist"][0]["current"] is True
        assert len(status["playlist"]) == 3
        assert get_order(status) == ["01", "02", "03"]

        send("playlist_jump", arg="1")
        status = get_status()
        assert status["playlist"][1]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        send("playlist_next")
        status = get_status()
        assert status["playlist"][2]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        send("playlist_prev")
        status = get_status()
        assert status["playlist"][1]["current"] is True
        assert get_order(status) == ["01", "02", "03"]

        send("playlist_move", arg="0/3")
        status = get_status()
        assert get_order(status) == ["02", "03", "01"]

        send("playlist_move_up", arg="1")
        status = get_status()
        assert get_order(status) == ["03", "02", "01"]

        def shuffle():
            # brute forcing shuffle :rolling_eyes:
            for _ in range(5):
                send("playlist_shuffle")
                order = get_order(get_status())
                if not order == ["03", "02", "01"]:
                    return True
            return False

        assert shuffle() is True, "playlist_shuffle failed!"

        # make sure we're not removing the current playlist entry
        send("playlist_jump", arg="0")
        order = get_order(get_status())
        send("playlist_remove", arg="2")
        status = get_status()
        assert len(status["playlist"]) == 2
        assert get_order(status) == order[:2]

    @staticmethod
    @pytest.mark.parametrize(
        "method",
        ["head", "patch", "not_a_valid_http_method"],
    )
    def test_not_allowed_methods(mpv_instance, method):
        resp = requests.request(method, f"{get_uri('api/status')}")
        assert resp.status_code == 405


def test_loadfile(mpv_instance):
    def send_loadfile(url, mode=None, expect=200):
        return send(
            "loadfile",
            urllib.parse.quote(url, safe=""),
            mode,
            status="playlist",
            expect=expect,
        )

    send("pause")
    status = get_status()
    assert status["playlist"][0]["current"] is True
    assert len(status["playlist"]) == 3

    playlist = send_loadfile("./environment/test_media/01 - dummy.mp3", "append-play")

    assert len(playlist) == 4
    assert playlist[-1]["filename"] == "./environment/test_media/01 - dummy.mp3"

    playlist = send_loadfile("./environment/test_media/01 - dummy.mp3", "append")

    assert len(playlist) == 5
    assert playlist[-2]["filename"] == "./environment/test_media/01 - dummy.mp3"
    assert playlist[-1]["filename"] == "./environment/test_media/01 - dummy.mp3"

    playlist = send_loadfile("./environment/test_media/01 - dummy.mp3", "replace")

    assert len(playlist) == 1
    assert playlist[0]["filename"] == "./environment/test_media/01 - dummy.mp3"

    playlist = send_loadfile("./environment/test_media/01 - dummy.mp3")

    assert len(playlist) == 1
    assert playlist[0]["filename"] == "./environment/test_media/01 - dummy.mp3"

    send_loadfile("./environment/test_media/01 - dummy.mp3", "not a valid mode", 400)


@pytest.mark.parametrize(
    "mpv_instance,status_code",
    [
        ({}, 404),
        (get_script_opts({"static_dir": "/app/tests/environment/static_test"}), 200),
        (get_script_opts({"static_dir": "/app/tests/environment/static_test/"}), 200),
        (get_script_opts({"static_dir": "environment/static_test"}), 200),
        (get_script_opts({"static_dir": "./environment/static_test/"}), 200),
    ],
    indirect=["mpv_instance"],
)
def test_static_dir_config(mpv_instance, status_code):
    resp = requests.get(get_uri("static.json"))
    assert resp.status_code == status_code

    if status_code == 200:
        assert resp.json() == {"success": True}


@pytest.mark.parametrize(
    "mpv_instance,expected_devices",
    [
        ({}, ["auto", "alsa", "jack", "sdl", "sndio"]),
        (
            get_script_opts({"audio_devices": "auto jack sndio"}),
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
        send("cycle_audio_device")
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

    send(endpoint)

    status = get_status()
    for track in status["track-list"]:
        if track["type"] == track_type:
            assert track["selected"] is False

    send(endpoint)

    status = get_status()
    for track in status["track-list"]:
        if track["type"] == track_type:
            assert track["selected"] is True


@pytest.mark.parametrize(
    "mpv_instance,v4_works,v6_works",
    [
        ({}, True, True),
        (get_script_opts({"ipv4": "no"}), False, True),
        (get_script_opts({"ipv6": "no"}), True, False),
        (get_script_opts({"disable": "yes"}), False, False),
    ],
    indirect=["mpv_instance"],
)
def test_disablers(mpv_instance, v4_works, v6_works):
    uri = get_uri("api/status", v=4)
    assert is_responding(uri) == v4_works
    uri = get_uri("api/status", v=6)
    assert is_responding(uri) == v6_works


@pytest.mark.parametrize(
    "mpv_instance,auth,status_code",
    [
        (get_script_opts({"htpasswd_path": "/tmp/.htpasswd"}), None, 401),
        (
            get_script_opts({"htpasswd_path": "/tmp/.htpasswd"}),
            HTTPBasicAuth("user", "wrong"),
            401,
        ),
        (
            get_script_opts({"htpasswd_path": "/tmp/.htpasswd"}),
            HTTPBasicAuth("user", "secret"),
            200,
        ),
        (get_script_opts({"htpasswd_path": "/app/.does-not-exist"}), None, None),
    ],
    indirect=["mpv_instance"],
)
def test_auth(htpasswd, mpv_instance, auth, status_code):
    try:
        resp = requests.get(get_uri("api/status"), auth=auth, timeout=0.5)
    except requests.exceptions.ReadTimeout:
        assert status_code is None
        return
    assert resp.status_code == status_code


@pytest.mark.parametrize(
    "mpv_instance,expected_8080,expected_8000",
    [({}, True, False), (get_script_opts({"port": "8000"}), False, True)],
    indirect=["mpv_instance"],
)
@pytest.mark.parametrize("v", [4, 6])
def test_port(mpv_instance, v, expected_8080, expected_8000):
    uri = get_uri("api/status", v=v, port=8080)
    assert is_responding(uri) == expected_8080

    uri = get_uri("api/status", v=v, port=8000)
    assert is_responding(uri) == expected_8000


@pytest.mark.parametrize(
    "mpv_instance,use_auth,username,password,status_code",
    [
        (get_script_opts({"logging": "yes"}), False, None, None, 200),
        (
            get_script_opts({"logging": "yes", "htpasswd_path": "/tmp/.htpasswd"}),
            True,
            "",
            "",
            401,
        ),
        (
            get_script_opts({"logging": "yes", "htpasswd_path": "/tmp/.htpasswd"}),
            True,
            "user",
            "secret",
            200,
        ),
        (
            get_script_opts({"logging": "yes", "htpasswd_path": "/tmp/.htpasswd"}),
            True,
            "user",
            "",
            401,
        ),
        (
            get_script_opts({"logging": "yes"}),
            False,
            "user",
            "secret",
            200,
        ),
    ],
    indirect=["mpv_instance"],
)
def test_logging(htpasswd, mpv_instance, use_auth, username, password, status_code):
    auth = None
    if use_auth and username:
        auth = HTTPBasicAuth(username, password)
    resp = requests.get(
        get_uri("api/status"), auth=auth, headers={"Referer": "https://referer"}
    )
    assert resp.status_code == status_code

    # example log line
    # ::1 - user [17/Apr/2020:13:18:22 +0000] "GET /api/status HTTP/1.1" 200 1253 "https://referer" "python-requests/2.23.0"
    user = "-"
    if username and auth:
        user = "user"

    assert (
        mpv_instance.expect(
            fr"\[webui\] ::1 - {user} \[\d\d?/[A-Z][a-z][a-z][a-z]?/?/\d{{4}}:\d{{2}}:\d{{2}}:\d{{2}} \+0{{4}}\] "
            fr'"GET /api/status HTTP/1.1" {status_code} \d* "https://referer" "python-requests/',
            timeout=1,
        )
        == 0
    )
