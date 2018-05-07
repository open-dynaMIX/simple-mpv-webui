# simple-mpv-webui
...is a web based user interface with controls for the [mpv mediaplayer](https://mpv.io/).

## Usage
To use it, simply copy `webui.lua` and the `webui-page`-folder to `~/.config/mpv/scripts/`, mpv will then run it 
automatically.

Alternatively you can also use the `--script` option from mpv or add something like 
`scripts-add=/path/to/simple-mpv-webui/webui.lua` to `mpv.conf`.

You can access the webui when accessing [http://127.0.0.1:8080](http://127.0.0.1:8080) or
[http://[::1]:8080](http://[::1]:8080) in your webbrowser.

By default it listens on `0.0.0.0:8080` and `[::0]:8080`. As described below, this can be changed.

### Options
 - `--script-opts=webui-port=${PORT}`: Set the port to serve the webui (default: 8080)
 - `--script-opts=webui-ipv4=no`: Disable listening on ipv4 (default: yes)
 - `--script-opts=webui-ipv6=no`: Disable listening on ipv6 (default: yes)
 - `--script-opts=webui-disable=yes`: Disable webui (default: no)
 - `--script-opts=webui-logging=yes`: Log requests in terminal (default: no)

### Authentication
There is a very simple implementation of
[Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication). It will be enabled, if a file
`.htpasswd` exists in the same directory as `webui.lua`. The file needs to
contain data in the following format:

```
user1:password1
user2:password2
```
Only plaintext `.htpasswd` entries are supported.

## Dependencies
 - [luasocket](https://github.com/diegonehab/luasocket)

## Screenshot
![screenshot](screenshots/webui.png#1)

## Media Session API
When using a browser that supports it, simple-mpv-webui uses the Media Session
API to provide a notification with some metadata and controls:

![notification](screenshots/notification.png#1)

In order to have the notification work properly you need to at least once trigger play from the webui.

## Endpoints
You can also directly talk to the endpoints:

| URI                        | Method | Parameter                          | Description                                                             |
| -------------------------- | ------ | ---------------------------------- | ----------------------------------------------------------------------- |
| /api/status                | GET    |                                    | Returns JSON data about playing media --> see below                     |
| /api/play                  | POST   |                                    | Play media                                                              |
| /api/pause                 | POST   |                                    | Pause media                                                             |
| /api/toggle_pause          | POST   |                                    | Toggle play/pause                                                       |
| /api/fullscreen            | POST   |                                    | Toggle fullscreen                                                       |
| /api/seek/:seconds         | POST   | `int` or `float` (can be negative) | Seek                                                                    |
| /api/set_position/:seconds | POST   |                                    | Go to position :seconds                                                 |
| /api/playlist_prev         | POST   |                                    | Go to previous media in playlist                                        |
| /api/playlist_next         | POST   |                                    | Go to next media in playlist                                            |
| /api/add_volume/:percent   | POST   | `int` or `float` (can be negative) | Add :percent% volume                                                    |
| /api/set_volume/:percent   | POST   | `int` or `float`                   | Set volume to :percent%                                                 |
| /api/add_sub_delay/:ms     | POST   | `int` or `float` (can be negative) | Add :ms milliseconds subtitles delay                                    |
| /api/set_sub_delay/:ms     | POST   | `int` or `float` (can be negative) | Set subtitles delay to :ms milliseconds                                 |
| /api/add_audio_delay/:ms   | POST   | `int` or `float` (can be negative) | Add :ms miliseconds audio delay                                         |
| /api/set_audio_delay/:ms   | POST   | `int` or `float` (can be negative) | Set audio delay to :ms milliseconds                                     |
| /api/cycle_sub             | POST   |                                    | Cycle trough available subtitles                                        |
| /api/cycle_audio           | POST   |                                    | Cycle trough available audio tracks                                     |
| /api/cycle_audio_device    | POST   |                                    | Cycle trough audio devices. This is hardcoded to `alsa` and `alsa/hdmi` |

All POST endpoints return a JSON message. If successful: `{"message": "success"}`, otherwise, the message will contain
information about the error.

### /api/status
`metadata` contains all the metadata mpv can see, below is just an example:

```
{'audio-delay': '0 ms',
 'duration': '208',
 'file': '1 - Never Gonna Give You Up.mp3',
 'metadata': {'album': 'Whenever You Need Somebody',
              'artist': 'Rick Astley',
              'date': '1987',
              'title': 'Never Gonna Give You Up',
              'track': '1'},
 'pause': 'no',
 'position': '10',
 'remaining': '197',
 'sub-delay': '0 ms',
 'volume': '100',
 'volume-max': '130'}

```

## Thanks
Thanks to [makedin](https://github.com/makedin) for his work on this.

## Differences to mpv-web-ui
 - More controls
 - Some styles and font-awesome
 - ipv6 support
 - Option to set the port being used (defaults to 8080)
 - Using the Media Session API

## Warning
These are my first steps with lua, so I'm just happy it works.
