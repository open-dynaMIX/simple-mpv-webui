var DEBUG = false;
var loaded = false;
var metadata = {};
var blockPosSlider = false;
var blockVolSlider = false;

function send(command, param){
  DEBUG && console.log('Sending command: ' + command + ' - param: ' + param);
  if ('mediaSession' in navigator) {
    audioLoad();
  }
  var path = command;
  if (param !== undefined)
    path += "/" + param;

  var request = new XMLHttpRequest();
  request.open("post", path);

  request.send(null);
}

function format_time(seconds){
  var date = new Date(null);
  date.setSeconds(seconds);
  return date.toISOString().substr(11, 8);
}

function setMetadata(metadata, filename) {
  if (metadata['track']) {
    var track = metadata['track'] + ' - ';
  } else {
    track = '';
  }
  if (metadata['title']) {
    window.title = track + metadata['title'];
  } else if (metadata['TITLE']) {
    window.metadata.title = track + metadata['TITLE'];
  } else {
    window.metadata.title = track + filename;
  }

  if (metadata['artist']) {
    window.metadata.artist = metadata['artist'];
  } else {
    window.metadata.artist = ''
  }

  if (metadata['album']) {
    window.metadata.album = metadata['album'];
  } else {
    window.metadata.album = ''
  }
}

function setPosSlider(duration, position) {
  var slider = document.getElementById("mediaPosition");
  var pos = document.getElementById("position");
  slider.max = duration;
  if (!window.blockPosSlider) {
    slider.value = position;
  }
  pos.innerHTML = format_time(slider.value);
}

document.getElementById("mediaPosition").onchange = function() {
  var slider = document.getElementById("mediaPosition");
  send("set_position", slider.value);
  window.blockPosSlider = false;
}

document.getElementById("mediaPosition").oninput = function() {
  window.blockPosSlider = true;
  var slider = document.getElementById("mediaPosition");
  var pos = document.getElementById("position");
  pos.innerHTML = format_time(slider.value);
}

function setVolumeSlider(volume) {
  var slider = document.getElementById("mediaVolume");
  var vol = document.getElementById("volume");
  if (!window.blockVolSlider) {
    slider.value = volume;
  }
  vol.innerHTML = slider.value + "%";
}

document.getElementById("mediaVolume").onchange = function() {
  var slider = document.getElementById("mediaVolume");
  send("set_volume", slider.value);
  window.blockVolSlider = false;
}

document.getElementById("mediaVolume").oninput = function() {
  window.blockVolSlider = true;
  var slider = document.getElementById("mediaVolume");
  var vol = document.getElementById("volume");
  vol.innerHTML = slider.value + "%";
}

function setPlayPause(value) {
  var playPause = document.getElementById("playPause");
  if (value === 'yes') {
    playPause.innerHTML = '<i class="fas fa-play"></i>';
    if ('mediaSession' in navigator) {
      audioPause();
    }
  } else {
    playPause.innerHTML = '<i class="fas fa-pause"></i>';
    if ('mediaSession' in navigator) {
      audioPlay();
    }
  }
}

function status(bottom = false){
  var request = new XMLHttpRequest();
  request.open("get", "/status");

  request.onreadystatechange = function(){
    if (request.readyState == 4 && request.status == 200) {
      var json = JSON.parse(request.responseText)
      setMetadata(json['metadata'], json['file']);
      document.getElementById("title").innerHTML = window.metadata.title;
      document.getElementById("artist").innerHTML = window.metadata.artist;
      document.getElementById("album").innerHTML = window.metadata.album;
      document.getElementById("duration").innerHTML =
        '&nbsp;'+ format_time(json['duration']);
      document.getElementById("remaining").innerHTML =
        "-" + format_time(json['remaining']);
      document.getElementById("sub-delay").innerHTML =
        json['sub-delay'];
      document.getElementById("audio-delay").innerHTML =
        json['audio-delay'];
      setPlayPause(json['pause']);
      setPosSlider(json['duration'], json['position']);
      setVolumeSlider(json['volume']);
      if ('mediaSession' in navigator) {
        setupNotification();
      }
      if (bottom) {
        window.scrollTo(0,document.body.scrollHeight);
      }
    } else if (request.status == 0) {
      document.getElementById("title").innerHTML = "<error>Couldn't connect to MPV!</error>";
      setPlayPause('yes');
    }
  }
  request.send(null);
}

function audioLoad() {
  if (!window.loaded) {
    DEBUG && console.log('Loading dummy audio');
    document.getElementById("audio").load();
    window.loaded = true;
  }
}

function audioPlay() {
  var audio = document.getElementById("audio");
  if (audio.paused) {
    DEBUG && console.log('Playing dummy audio');
    audio.play();
  }
}

function audioPause() {
  var audio = document.getElementById("audio");
  if (!audio.paused) {
    DEBUG && console.log('Pausing dummy audio');
    audio.pause();
  }
}

function setupNotification() {
  if ('mediaSession' in navigator) {
    navigator.mediaSession.metadata = new MediaMetadata({
      title: window.metadata.title,
      artist: window.metadata.artist,
      album: window.metadata.album,
      artwork: [
        { src: '/favicons/android-chrome-192x192.png', sizes: '192x192', type: 'image/png' },
        { src: '/favicons/android-chrome-512x512.png', sizes: '512x512', type: 'image/png' },
      ]
    });

    navigator.mediaSession.setActionHandler('play', function() {send('play');});
    navigator.mediaSession.setActionHandler('pause', function() {send('pause');});
    navigator.mediaSession.setActionHandler('seekbackward', function() {send('seek', '-10');});
    navigator.mediaSession.setActionHandler('seekforward', function() {send('seek', '10');});
    navigator.mediaSession.setActionHandler('previoustrack', function() {send('playlist_prev');});
    navigator.mediaSession.setActionHandler('nexttrack', function() {send('playlist_next');});
  }
}

status();
setInterval(function(){status();}, 1000);
