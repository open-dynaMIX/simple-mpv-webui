var DEBUG = false;
    loaded = false;
    metadata = {};
    subs = {};
    audios = {};
    blockPosSlider = false;
    blockVolSlider = false;

function send(command, param){
  DEBUG && console.log('Sending command: ' + command + ' - param: ' + param);
  if ('mediaSession' in navigator) {
    audioLoad();
  }
  var path = 'api/' + command;
  if (param !== undefined)
    path += "/" + param;

  var request = new XMLHttpRequest();
  request.open("post", path);

  request.send(null);
}

function togglePlaylist() {
  document.body.classList.toggle('noscroll');
  var el = document.getElementById("overlay");
  el.style.visibility = (el.style.visibility === "visible") ? "hidden" : "visible";
}

function createPlaylistTable(entry, position, pause) {
  if (entry.title) {
    var title = entry.title;
  } else {
    var filename_array = entry.filename.split('/');
    title = filename_array[filename_array.length - 1];
  }

  var table = document.createElement('table');
  var tr = document.createElement('tr');
  var td_right = document.createElement('td');
  var td_left = document.createElement('td');
  table.className = 'playlist';
  tr.className = 'playlist';
  td_right.className = 'playlist';
  td_left.className = 'playlist';
  td_right.innerText = title;

  if (entry.hasOwnProperty('playing')) {
    if (pause) {
      td_left.innerHTML = '<i class="fas fa-pause"></i>';
    } else {
      td_left.innerHTML = '<i class="fas fa-play"></i>';
    }

    table.classList.add('playing');
    table.classList.add('violet');

  } else {
    table.classList.add('gray');
    table.onclick = function(arg) {
        return function() {
            send("playlist_jump", arg);
            return false;
        }
    }(position);
  }
  tr.appendChild(td_left);
  tr.appendChild(td_right);
  table.appendChild(tr);
  return table;
}

function populatePlaylist(json, pause) {
  var playlist = document.getElementById('playlist');
  playlist.innerHTML = "";

  for(var i = 0; i < json.length; ++i) {
      playlist.appendChild(createPlaylistTable(json[i], i, pause));
  }
}

window.onkeydown = function(e) {
  if (e.keyCode === 32 || e.key === ' ') {
    send('toggle_pause');
    return false;
  }
  if (e.keyCode === 39 || e.key === 'ArrowRight') {
    send('seek', '10');
    return false;
  }
  if (e.keyCode === 37 || e.key === 'ArrowLeft') {
    send('seek', '-10');
    return false;
  }
};

function format_time(seconds){
  var date = new Date(null);
  date.setSeconds(seconds);
  return date.toISOString().substr(11, 8);
}

function setFullscreenButton(fullscreen) {
    if (fullscreen) {
        var fullscreenText = 'Fullscreen off';
    } else {
        fullscreenText = 'Fullscreen on';
    }
    document.getElementById("fullscreenButton").innerText =
        fullscreenText;
}

function setTrackList(tracklist) {
  window.audios.selected = 0;
  window.audios.count = 0;
  window.subs.selected = 0;
  window.subs.count = 0;
  for (var i = 0; i < tracklist.length; i++){
    if (tracklist[i].type === 'audio') {
      window.audios.count++;
      if (tracklist[i].selected) {
          window.audios.selected = tracklist[i].id;
      }
    } else if (tracklist[i].type === 'sub') {
      window.subs.count++;
      if (tracklist[i].selected) {
          window.subs.selected = tracklist[i].id;
      }
    }
  }
  document.getElementById("nextSub").innerText = 'Next sub ' + window.subs.selected + '/' + window.subs.count;
  document.getElementById("nextAudio").innerText = 'Next audio ' + window.audios.selected + '/' + window.audios.count;
}

function setMetadata(metadata, playlist, filename) {
  // try to gather the track number
  if (metadata['track']) {
    var track = metadata['track'] + ' - ';
  } else {
    track = '';
  }

  // try to gather the playing playlist element
  for (var i = 0; i < playlist.length; i++){
    if (playlist[i].hasOwnProperty('playing')) {
       var pl_title = playlist[i].title;
    }
  }
  // set the title. Try values in this order:
  // 1. title set in playlist
  // 2. metadata['title']
  // 3. metadata['TITLE']
  // 4. filename
  if (pl_title) {
    window.metadata.title = track + pl_title;
  } else if (metadata['title']) {
    window.metadata.title = track + metadata['title'];
  } else if (metadata['TITLE']) {
    window.metadata.title = track + metadata['TITLE'];
  } else {
    window.metadata.title = track + filename;
  }

  // set the artist
  if (metadata['artist']) {
    window.metadata.artist = metadata['artist'];
  } else {
    window.metadata.artist = ''
  }

  // set the album
  if (metadata['album']) {
    window.metadata.album = metadata['album'];
  } else {
    window.metadata.album = ''
  }

  document.getElementById("title").innerHTML = window.metadata.title;
  document.getElementById("artist").innerHTML = window.metadata.artist;
  document.getElementById("album").innerHTML = window.metadata.album;
}

function setPosSlider(position, duration) {
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
};

document.getElementById("mediaPosition").oninput = function() {
  window.blockPosSlider = true;
  var slider = document.getElementById("mediaPosition");
  var pos = document.getElementById("position");
  pos.innerHTML = format_time(slider.value);
};

function setVolumeSlider(volume, volumeMax) {
  var slider = document.getElementById("mediaVolume");
  var vol = document.getElementById("volume");
  if (!window.blockVolSlider) {
    slider.value = volume;
    slider.max = volumeMax;
  }
  vol.innerHTML = slider.value + "%";
}

document.getElementById("mediaVolume").onchange = function() {
  var slider = document.getElementById("mediaVolume");
  send("set_volume", slider.value);
  window.blockVolSlider = false;
};

document.getElementById("mediaVolume").oninput = function() {
  window.blockVolSlider = true;
  var slider = document.getElementById("mediaVolume");
  var vol = document.getElementById("volume");
  vol.innerHTML = slider.value + "%";
};

function setPlayPause(value) {
  var playPause = document.getElementsByClassName('playPauseButton');

  // var playPause = document.getElementById("playPause");
  if (value) {
    [].slice.call(playPause).forEach(function (div) {
      div.innerHTML = '<i class="fas fa-play"></i>';
    });
    if ('mediaSession' in navigator) {
      audioPause();
    }
  } else {
    [].slice.call(playPause).forEach(function (div) {
      div.innerHTML = '<i class="fas fa-pause"></i>';
    });
    if ('mediaSession' in navigator) {
      audioPlay();
    }
  }
}

function handleStatusResponse(json) {
  setMetadata(json['metadata'], json['playlist'], json['filename']);
  setTrackList(json['track-list']);
  document.getElementById("duration").innerHTML =
    '&nbsp;'+ format_time(json['duration']);
  document.getElementById("remaining").innerHTML =
    "-" + format_time(json['remaining']);
  document.getElementById("sub-delay").innerHTML =
    json['sub-delay'] + ' ms';
  document.getElementById("audio-delay").innerHTML =
    json['audio-delay'] + ' ms';
  setPlayPause(json['pause']);
  setPosSlider(json['position'], json['duration']);
  setVolumeSlider(json['volume'], json['volume-max']);
  setFullscreenButton(json['fullscreen']);
  populatePlaylist(json['playlist'], json['pause']);
  if ('mediaSession' in navigator) {
    setupNotification();
  }
}

function status(){
  var request = new XMLHttpRequest();
  request.open("get", "/api/status");

  request.onreadystatechange = function() {
    if (request.readyState === 4 && request.status === 200) {
      var json = JSON.parse(request.responseText);
      handleStatusResponse(json);
    } else if (request.status === 0) {
      document.getElementById("title").innerHTML = "<h1><span class='error'>Couldn't connect to MPV!</span></h1>";
      document.getElementById("artist").innerHTML = "";
      document.getElementById("album").innerHTML = "";
      setPlayPause(true);
    }
  };
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
    audio.play().then(function() {
      DEBUG && console.log('Playing dummy audio');
    });
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
        { src: '/favicons/android-chrome-512x512.png', sizes: '512x512', type: 'image/png' }
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

// prevent zoom-in on double-click
// https://stackoverflow.com/questions/37808180/disable-viewport-zooming-ios-10-safari/38573198#38573198
var lastTouchEnd = 0;
document.addEventListener('touchend', function (event) {
  var now = (new Date()).getTime();
  if (now - lastTouchEnd <= 300) {
    event.preventDefault();
  }
  lastTouchEnd = now;
}, false);
