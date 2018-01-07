function send(command, param){
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

function playPause(value) {
  if (value === 'yes') {
    return '<i class="fas fa-play"></i>'
  } else {
    return '<i class="fas fa-pause"></i>'
  }
}

function status(bottom = false){
  var request = new XMLHttpRequest();
  request.open("get", "/status");

  request.onreadystatechange = function(){
    if (request.readyState == 4 && request.status == 200){
      var json = JSON.parse(request.responseText)
      document.getElementById("filename").innerHTML = json['file'];
      document.getElementById("duration").innerHTML =
        format_time(json['duration']);
      document.getElementById("position").innerHTML =
        format_time(json['position']);
      document.getElementById("remaining").innerHTML =
        format_time(json['remaining']);
      document.getElementById("sub-delay").innerHTML =
        json['sub-delay'] * 1000;
      document.getElementById("volume").innerHTML =
        Math.floor(json['volume']) + "%";
      document.getElementById("playPause").innerHTML =
        playPause(json['pause']);
      if (bottom) {
        window.scrollTo(0,document.body.scrollHeight);
      }
    }
  }

  request.send(null);
}

status();
setInterval(function(){status();}, 2000);
