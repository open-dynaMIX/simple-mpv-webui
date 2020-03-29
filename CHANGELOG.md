# Changelog

## v0.3.0
### Feature
* add "audio-support" to status response (c66a29f01165446b34a798774165e4d4f12f7374)
* do not round time and volume values (cabf7dbe297a1161aa555bb4de3ded13628225ce)
* hide chapter controls if media has no chapters (8974f9405ca8a92e75da4a23a7b28b8cffe2867f)
* add more key bindings (95243d449eea2e70c5bf84ca329e66d6d2a491b3)

### Documentation
* add a section with a link to windows dependencies repo (10db3814aae26c9a3e496c77a3ad11b5c6f8585e)


## v0.2.1
### Fix
* fix playlist_move validation (7500b4f8819964b9f7e47edd8ae494a697ce4899)
* use events for sending startup notification (067eb23f2c8a3cbe1d395198d60479f95bdf4f12)


## v0.2.0
### Feature
* restyle range input sliders (d2a8a696413faccc275ab4abe2a0dcb5adc6262e)
* add more controls to playlist (2e47afa4fd8c78bcda9a8ac250bded1ee58733d3)
* add playlist_move endpoint (43197eb637a4f4bef9cf1a13d2be528babbe3362)
* refactor playlist controls; add more buttons (7ba4e26d905c9d0ea4cb18ff386c30e930329a4e)
* display chapter info and handle missing chapters (923570ea62a963e3a38204820d856690d7f61aeb)

### Fix
* fix referencing values not present (cf63945e1bf4b01f10a479335e2bde9cda457b0b)
* do not call status() after playlist jump (de21e17e69976fb667bfd816664fb5ae70d7ca17)
* handle empty requests and query params (5c7da039080252144a071aaebbef00cbffcd8409)


## v0.1.0
### Feature
 - Add chapter seeking buttons [#6](https://github.com/open-dynaMIX/simple-mpv-webui/pull/6) *Thanks to @Nebukadneza!*

### Fix
 - prevent zoom-in on double-click [#8](https://github.com/open-dynaMIX/simple-mpv-webui/pull/8)  *Thanks to @rofrol!*
 - Log a warning if a property could not be fetched from mpv [
0d42e81](https://github.com/open-dynaMIX/simple-mpv-webui/commit/0d42e81baa849af969f9dbf803f763106ca9d4e1)


## v0.0.1

Initial release.
