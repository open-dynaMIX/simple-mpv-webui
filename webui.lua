socket = require("socket")
local open = io.open

host = "::"
port = "8080"
server = assert(socket.bind(host, port))
server:settimeout(0)

commands = {
  pause = function()
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

  prev = function(t)
    mp.command("playlist-prev")
  end,

  next = function(t)
    mp.command("playlist-next")
  end,

  volume = function(v)
    mp.command('add volume '..v)
  end,

  sub_delay = function(v)
    mp.command('add sub-delay '..v)
  end,

  cycle_sub = function(v)
    mp.command("cycle sub")
  end,

  cycle_audio = function(v)
    mp.command("cycle audio")
  end,

  cycle_audio_device = function(v)
    mp.command("cycle_values audio-device alsa alsa/hdmi")
  end
}

function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local function sleep(n)
  os.execute("sleep " .. tonumber(n))
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
  end
end

local function read_file(path)
    local file = open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

function header(code, content_type)
  local h = ""
  if code == 200 then
    h = h.."HTTP/1.1 200 OK\n"

    h = h.."Content-Type: "..content_type.."\n"

  elseif code == 404 then
    h = h.."HTTP/1.1 404 Not Found\n"
  end

  return h.."Connection: close\n\n"
end

local function get_prop(property, placeholder)
  placeholder = placeholder or 'unknown'
  local prop = mp.get_property(property)
  if prop == nil then
    prop = placeholder
  end
  return prop
end

function listen()
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
      local response = ""

      if (path == "status") then
        sleep(.2)
        connection:send(header(200, get_content_type("json")))

        local json = [[{"file":"]]..get_prop("path")..'",'
        json = json..'"duration":"'..get_prop("duration")..'",'
        json = json..'"position":"'..get_prop("time-pos")..'",'
        json = json..'"remaining":"'..get_prop("playtime-remaining")..'",'
        json = json..'"sub-delay":"'..get_prop("sub-delay")..'",'
        json = json..'"volume":"'..get_prop("volume")..'"}'

        connection:send(json)
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
mp.add_periodic_timer(0.2, listen)
