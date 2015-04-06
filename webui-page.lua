page = [[<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="user-scalable=no">
    <title>mpv webui</title>
  </head>
  <h1 id="filename">Filename</h1>
  <h2 id="length">file length</h1>
  <h2 id="volume">volume</h1>
  <body>
    <div onClick="send('pause')" id="play" class="button">play / pause</div>

    <div onClick="send('seek', '-5')" class="button seek left">&lt;&lt;</div>
    <div onClick="send('seek', '5')" class="button seek right">&gt;&gt;</div>

    <div onClick="send('volume', '-5')" class="button vol left">-</div>
    <div onClick="send('volume', '5')" class="button vol right">+</div>

  </body>

  <style>
body {
  max-width: 100%;
}
.button {
  text-align: center;
  height: 150px;
  border-radius: 6px;
  font-size: 100px;
    margin-bottom: 15px;
}
#play {
  width: 100%;
  background-color: #6f6;
}
.seek {
  width: 49%;
  background-color: #66f;
}
.vol {
  width: 49%;
  background-color: #999;
}
.right {
  float: right;
}
.left {
  float: left;
}

  </style>

  <script>
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

function status(){
  var request = new XMLHttpRequest();
  request.open("get", "/status");

  request.onreadystatechange = function(){
    if (request.readyState == 4 && request.status == 200){
      var json = JSON.parse(request.responseText)
      document.getElementById("filename").innerHTML = json['file'];
      document.getElementById("length").innerHTML = "duration: " +
        format_time(json['length']);
      document.getElementById("volume").innerHTML = "volume: " +
        Math.floor(json['volume']) + "%";
    }
  }

  request.send(null);
}

status();
  </script>
</html>
]]
