var DEBUG = false;
var loaded = false;
var metadata = null;
var filename = null;

function send(command, param){
  DEBUG && console.log('Sending command: ' + command + ' - param: ' + param);
  if ('mediaSession' in navigator) {
    if (command === 'toggle_pause') {
      loadAudio();
    }
  }
  var path = command;
  if (param !== undefined)
    path += "/" + param;

  var request = new XMLHttpRequest();
  request.open("post", path);

  request.onreadystatechange = function(){
    if (request.readyState == 4 && request.status == 200){
      status();
    }
  }

  request.send(null);
}

function loadAudio() {
  if (!window.loaded) {
    DEBUG && console.log('Loading dummy audio');
    document.getElementById("audio").load();
    window.loaded = true;
  }
}

function format_time(seconds){
  var hours = Math.floor(seconds / 3600);
  var minutes = Math.floor((seconds - (hours * 3600)) / 60);
  var seconds = Math.floor(seconds - hours * 3600 - minutes * 60)

  if (hours < 10)
    hours = "0" + hours;

  if (minutes < 10)
    minutes = "0" + minutes;

  if (seconds < 10)
    seconds = "0" + seconds;

  return hours + ":" + minutes + ":" + seconds;
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
      setupNotification();
    }
  }
}

function getTitle() {
  if (window.metadata['title']) {
    return window.metadata['title'];
  } else if (window.metadata['TITLE']) {
    return window.metadata['TITLE'];
  } else if (window.filename) {
    return window.filename;
  }
}

function status(bottom = false){
  var request = new XMLHttpRequest();
  request.open("get", "/status");

  request.onreadystatechange = function(){
    if (request.readyState == 4 && request.status == 200){
      var json = JSON.parse(request.responseText)
      window.metadata = json['metadata'];
      window.filename = json['file'];
      document.getElementById("filename").innerHTML = getTitle();
      document.getElementById("duration").innerHTML =
        format_time(json['duration']);
      document.getElementById("position").innerHTML =
        format_time(json['position']);
      document.getElementById("remaining").innerHTML =
        format_time(json['remaining']);
      document.getElementById("sub-delay").innerHTML =
        json['sub-delay'] * 1000 + ' ms';
      document.getElementById("audio-delay").innerHTML =
        json['audio-delay'] * 1000 + ' ms';
      document.getElementById("volume").innerHTML =
        Math.floor(json['volume']) + "%";
      setPlayPause(json['pause']);
      if (bottom) {
        window.scrollTo(0,document.body.scrollHeight);
      }
    }
  }

  request.send(null);
}

function audioPlay(){
  var audio = document.getElementById("audio");
  if (audio.paused) {
    DEBUG && console.log('Playing dummy audio');
    audio.play();
    setupNotification();
  }
}

function audioPause(){
  var audio = document.getElementById("audio");
  if (!audio.paused) {
    DEBUG && console.log('Pausing dummy audio');
    audio.pause();
    setupNotification();
  }
}

function setupNotification() {
  if ('mediaSession' in navigator) {
    if (window.metadata['artist']) {
      var artist = window.metadata['artist'];
    }
    if (window.metadata['album']) {
      var album = window.metadata['album'];
    }
    navigator.mediaSession.metadata = new MediaMetadata({
      title: getTitle(),
      artist: artist,
      album: album,
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
setInterval(function(){status();}, 2000);
