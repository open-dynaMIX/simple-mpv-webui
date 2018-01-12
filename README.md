# simple-mpv-webui
...is a web based user interface with controls for the [mpv mediaplayer](https://mpv.io/). It serves a web page on port 8080.

## Usage
To use it, simply copy `webui.lua` and the `webui-page`-folder to `~/.mpv/scripts`, mpv will then run it automatically.

Alternatively you can also use the `--script` option from mpv or add something like `scripts-add=/path/to/simple-mpv-webui/webui.lua` to `mpv.conf`.

Note that as the port is hard coded, only one instance can be run at a time. This should be quite trivial to fix.

## Dependencies
 - [luasocket](https://github.com/diegonehab/luasocket)

## Screenshot
![screenshot](screenshots/webui.png)

## Media Session API
When using a browser that supports it, simple-mpv-webui uses the Media Session
API to provide a notification with some metadata and controls:

![notification](screenshots/notification.png)

## Differences to mpv-web-ui
 - More controls
 - Some styles and font-awesome
 - Works also with ipv6

## Warning
These are my first steps with lua, so I'm just happy it works.
