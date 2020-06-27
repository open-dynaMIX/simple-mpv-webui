# Changelog

## v1.1.0
### Feature
* add static_dir configuration (280d5a6e8ef4b562e454c0447ba483ce9bb2acab)

### Fix
* rebuild audio-devices during runtime (637006838aba850bcbfdd837f7e5186b9cec44ba)
* fix display of error message if server fails to start (2c3eb9e2d231ddf872dd297b1f9bc5d33583a985)


## v1.0.0
### Feature
* allow lower case header names (d37a27a8dc67e09a890130d7651602eef871c907)
* include audio-device information in status response (c81cf3b402726a97492639c7651b794f0570c388)

### Fix
* use floats in status json (51ee82143fdc8e61df80dc378f01bbf5c7467d47)
* also print startup_msg to shell (4825a7733f6e52e283f23944f127b6376225028b)
* fix loop handling in frontend (42b3704cb84ac8b0df12e9fae12536ad32539981)
* fix audio-device cycling when audio_devices option is not provided (7e00756ce4c2ca573bc2afc1ba67d45f5ceb3161)

### Breaking
* The type of the duration and volume properties has changed from string to float in the status response.  (51ee82143fdc8e61df80dc378f01bbf5c7467d47)

### Documentation
* fix json in readme (cd8272c093550d524e66604cc6606ee7bc87c831)
* delays are transmitted in seconds, not ms (2b9d23b8091cf6067722970cffcbc2cf7d2a71ae)
* fix typo `audio-devices`/`audio_devices` (c83b9949dabfe1b10c21329cb221f725f9746677)
* fix typo `audio-devices`/`audio_devices` (4fc63269ef84f25a2e7a5d510508f5c91aa7b981)


## v0.3.1
### Fix
* fix reference to audio-devices-list property (604797d24b6009f51a156f889f23df6b71d80d26)

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
