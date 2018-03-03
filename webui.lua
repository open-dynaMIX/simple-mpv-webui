socket = require("socket")
require 'mp.options'

local options = {
    port = 8080,
}
read_options(options, "webui")

local commands = {
  play = function()
    mp.set_property_bool("pause", false)
  end,

  pause = function()
    mp.set_property_bool("pause", true)
  end,

  toggle_pause = function()
    local curr = mp.get_property_bool("pause")
    mp.set_property_bool("pause", not curr)
  end,

  fullscreen = function()
    local curr = mp.get_property_bool("fullscreen")
    mp.set_property_bool("fullscreen", not curr)
  end,

  seek = function(t)
    mp.command("seek "..t)
  end,

  set_position = function(t)
    mp.set_property("time-pos", t)
  end,

  playlist_prev = function()
    local position = tonumber(mp.get_property("time-pos"))
    if position > 1 then
      mp.command("seek "..-position)
    else
      mp.command("playlist-prev")
    end
  end,

  playlist_next = function()
    mp.command("playlist-next")
  end,

  add_volume = function(v)
    mp.command('add volume '..v)
  end,

  set_volume = function(v)
    mp.command('set volume '..v)
  end,

  sub_delay = function(ms)
    mp.command('add sub-delay '..ms)
  end,

  audio_delay = function(ms)
    mp.command('add audio-delay '..ms)
  end,

  cycle_sub = function()
    mp.command("cycle sub")
  end,

  cycle_audio = function()
    mp.command("cycle audio")
  end,

  cycle_audio_device = function()
    mp.command("cycle_values audio-device alsa alsa/hdmi")
  end
}

local function init_server()
  local msg_prefix = "[webui]"

  local host = "0.0.0.0"

  server = socket.bind(host, options.port)

  if server == nil then
    mp.osd_message("osd-msg1", msg_prefix..
      " couldn't spawn server on port "..options.port, 2)
  else
    mp.osd_message(msg_prefix.." serving on port "..options.port, 2)
  end
  assert(server)

  server:settimeout(0)
end

local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local function get_content_type(file_type)
  if file_type == 'html' then
    return 'text/html; charset=UTF-8'
  elseif file_type == 'json' then
    return 'application/json; charset=UTF-8'
  elseif file_type == 'js' then
    return 'application/javascript; charset=UTF-8'
  elseif file_type == 'png' then
    return 'image/png'
  elseif file_type == 'ico' then
    return 'image/x-icon'
  elseif file_type == 'svg' then
    return 'image/svg+xml'
  elseif file_type == 'xml' then
    return 'application/xml; charset=UTF-8'
  elseif file_type == 'css' then
    return 'text/css; charset=UTF-8'
  elseif file_type == 'woff2' then
    return 'font/woff2; charset=UTF-8'
  elseif file_type == 'mp3' then
    return 'audio/mpeg'
  end
end

local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

local function header(code, content_type)
  local h = ""
  if code == 200 then
    h = h.."HTTP/1.1 200 OK\n"

    h = h.."Content-Type: "..content_type.."\n"

  elseif code == 404 then
    h = h.."HTTP/1.1 404 Not Found\n"
  end

  return h.."Connection: close\n\n"
end

function round(a)
  return (a - a % 1) / 1
end

local function listen()
  local connection = server:accept()
  if connection == nil then
    return
  end

  local line = connection:receive()
  while line ~= nil and line ~= "" do
    local request = string.gmatch(line, "%S+")
    local method = request()
    local path = string.sub(request(), 2)

    if method == "POST" then
      local components = string.gmatch(path, "[^/]+")
      local command = components() or path
      local param = components() or ""

      local f = commands[command]
      if f ~= nil then
        f(param);
        connection:send(header(200, get_content_type("html")))
      else
        connection:send(header(404, nil))
      end

      connection:close()
      return

    elseif method == "GET" then

      if (path == "status") then
        socket.sleep(.2)
        local duration = round(mp.get_property("duration"))
        if (duration == nil) then
          connection:send(header(503, nil))
        else
          connection:send(header(200, get_content_type("json")))

          local json = [[{"file":"]]..mp.get_property('filename')..'",'
          json = json..'"duration":"'..duration..'",'
          json = json..'"position":"'..round(mp.get_property("time-pos"))..'",'
          json = json..'"pause":"'..mp.get_property("pause")..'",'
          json = json..'"remaining":"'..round(mp.get_property("playtime-remaining"))..'",'
          json = json..'"sub-delay":"'..mp.get_property_osd("sub-delay")..'",'
          json = json..'"audio-delay":"'..mp.get_property_osd("audio-delay")..'",'
          json = json..'"metadata":'..mp.get_property("metadata")..','
          json = json..'"volume":"'..round(mp.get_property("volume"))..'"}'

          connection:send(json)
        end
        connection:close()
        return
      else
        if path == "" then
          path = 'index.html'
        end
        local extension = path:match("[^.]+$") or ""
        local content = read_file(script_path()..'webui-page/'..path)
        local content_type = get_content_type(extension)
        if content == nil or content_type == nil then
          connection:send(header(404, nil))
        else
          connection:send(header(200, content_type))
          connection:send(content)
        end
        connection:close()
        return
      end
    end
  end
end


init_server()
mp.add_periodic_timer(0.2, listen)
