page = [[<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="user-scalable=no">
    <title>mpv webui</title>
  </head>
  <body>
    <div onClick="ajax('pause')" id="play" class="button">play / pause</div>

    <div onClick="ajax('seek', '-5')" class="button seek left">&lt;&lt;</div>
    <div onClick="ajax('seek', '5')" class="button seek right">&gt;&gt;</div>

    <div onClick="ajax('volume', '-5')" class="button vol left">-</div>
    <div onClick="ajax('volume', '5')" class="button vol right">+</div>
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
function ajax(command, param){
  var path = command;
  if (param !== undefined)
    path += "/" + param;

  var request = new XMLHttpRequest();
  request.open("post", path);
  request.send(null);
}
  </script>
</html>
]]
