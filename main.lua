require 'mp.options'
require 'mp.msg'
utils = require 'mp.utils'
local socket = require("socket")
local dec64 = require("mime").decode("base64")
local url = require("socket.url")

local MSG_PREFIX = "[webui] "
local VERSION = "2.2.0"

function string.starts(String, Start)
  return string.sub(String,1,string.len(Start))==Start
end

local function script_path()
  -- https://stackoverflow.com/questions/6380820/get-containing-path-of-lua-file/35072122#35072122
  return debug.getinfo(1).source:match("@?(.*/)")
end

local options = {
  port = 8080,
  disable = false,
  logging = false,
  osd_logging = true,
  ipv4 = true,
  ipv6 = true,
  audio_devices = '',
  static_dir = script_path() .. "webui-page",
  htpasswd_path = "",
}
read_options(options, "webui")

local function table_key_concat(tab, sep)
  local ctab, n = {}, 1
  for k, _ in pairs(tab) do
    ctab[n] = k
    n = n + 1
  end
  return table.concat(ctab, sep)
end

local function validate_number_param(param)
  if not tonumber(param) then
    return false, 'Parameter needs to be an integer or float'
  end
  return true, nil
end

local function validate_name_param(param)
  if not string.match(param, '^[a-z0-9_/-]+$') then
    return false, 'Parameter name contains invalid characters'
  end
  return true, nil
end

local function validate_value_param(param)
  if not string.match(param, '^%g+$') then
    return false, 'Parameter value contains invalid characters'
  end
  return true, nil
end

local function validate_cycle_param(param)
  if param ~= 'up' and param ~= 'down' then
    return false, 'Cycle paramater is not "up" or "down"'
  end
  return true, nil
end

local function validate_loop_param(param, valid_table)
  for _, value in pairs(valid_table) do
    if value == param then
      return true, nil
    end
  end
  valid, msg = validate_number_param(param)
  if not valid then
    return false, "Invalid parameter!"
  end
  return true, nil
end

local function get_audio_devices()
  local active_device = mp.get_property_native("audio-device")
  local audio_devices = {}
  for _, device in pairs(mp.get_property_native("audio-device-list")) do
    if options.audio_devices == "" or options.audio_devices == device.name
              or string.find(options.audio_devices, " "..device.name, 1, true)
              or string.find(options.audio_devices, device.name.." ", 1, true)
    then
      audio_devices[#audio_devices+1] = {
            name = device.name,
            description = device.description,
            active = device.name == active_device
      }
    end
  end

  return audio_devices
end

local function get_audio_devices_list()
  local audio_devices = get_audio_devices()
  local devices_list = {}

  for n, v in pairs(audio_devices) do
    devices_list[n] = v.name
  end
  return devices_list
end

local function build_status_response()
  local values = {
    ["audio-delay"] = mp.get_property_osd("audio-delay") or '',
    ["audio-devices"] = get_audio_devices(),
    chapter = mp.get_property_native("chapter") or 0,
    ["chapter-list"] = mp.get_property_native("chapter-list") or '',
    chapters = mp.get_property_native("chapters") or '',
    duration = mp.get_property_native("duration") or '',
    filename = mp.get_property('filename') or '',
    fullscreen = mp.get_property_native("fullscreen"),
    ["loop-file"] = mp.get_property_native("loop-file"),
    ["loop-playlist"] = mp.get_property_native("loop-playlist"),
    metadata = mp.get_property_native("metadata") or '',
    pause = mp.get_property_native("pause"),
    playlist = mp.get_property_native("playlist") or '',
    position = mp.get_property_native("time-pos") or '',
    remaining = mp.get_property_native("playtime-remaining") or '',
    speed = mp.get_property_native('speed') or '',
    ["sub-delay"] = mp.get_property_osd("sub-delay") or '',
    ["track-list"] = mp.get_property_native("track-list") or '',
    volume = mp.get_property_native("volume") or '',
    ["volume-max"] = mp.get_property_native("volume-max") or '',
    ["webui-version"] = VERSION,
  }

  for _, value in pairs({"fullscreen", "loop-file", "loop-playlist", "pause"}) do
    if values[value] == nil then
      values[value] = ''
    end
  end

  for _, value in pairs({"audio-delay", "sub-delay"}) do
    if values[value] ~= nil then
      values[value] = tonumber(values[value]:sub(1, -4))
    end
  end

  -- We need to check if the value is available.
  -- If the file just started playing, mp-functions return nil for a short time.

  fail = false
  for k, v in pairs(values) do
    if v == '' and options.logging then
      mp.msg.warn('Could not fetch "'.. k .. '" from mpv.')
      fail = true
    end
  end

  if fail and options.logging then
      mp.msg.warn('This is normal during startup.')
      return false
  end

  return utils.format_json(values)
end

local function get_content_type(file_type)
  content_types = {
    html        = "text/html; charset=UTF-8",
    plain       = "text/plain; charset=UTF-8",
    json        = "application/json; charset=UTF-8",
    js          = "application/javascript; charset=UTF-8",
    png         = "image/png",
    ico         = "image/x-icon",
    svg         = "image/svg+xml",
    xml         = "application/xml; charset=UTF-8",
    css         = "text/css; charset=UTF-8",
    woff2       = "font/woff2; charset=UTF-8",
    mp3         = "audio/mpeg",
    webmanifest = "application/manifest+json; charset=UTF-8",
  }
  content_type = content_types[file_type]
  if content_type == nil then
    error('Content type for file type "'..file_type..'" not found!')
  end
  return content_type
end

local function headers(code, content_type, content_length, add_headers)
  if add_headers == nil then
    add_headers = {}
  end

  custom_headers = ""
  for key,value in pairs(add_headers) do
    custom_headers = custom_headers .. "\n" .. key .. ": " .. value
  end

  local status_headers = {
    [200] = "OK",
    [204] = "No Content",
    [400] = "Bad Request",
    [401] = 'Unauthorized\nWWW-Authenticate: Basic realm="Simple MPV WebUI"',
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [503] = "Service Unavailable"
  }

  return ([[HTTP/1.1 %s %s
Access-Control-Allow-Origin: *
Content-Type: %s
Content-Length: %s%s
Server: simple-mpv-webui
Connection: close

]]):format(
          tostring(code),
          status_headers[code],
          content_type,
          content_length,
          custom_headers
  )
end

local function response(code, file_type, content, add_headers)
  local content_type = get_content_type(file_type)
  return {
    code = code,
    content_length = #content,
    content = content,
    content_type = content_type,
    add_headers = add_headers,
    headers = headers(code, content_type, #content, add_headers),
  }
end

local function handle_post(success, msg)
  if success and msg == nil then
    msg = "success"
  end
  response_json = utils.format_json({message = msg})
  if success then
    return response(200, 'json', response_json, {})
  end
  return response(400, "json", response_json, {})
end

local endpoints = {
  ["api/status"] = {
    GET = function(_)
      local json = build_status_response()
      if not json then
        return response(503, "plain", "Error: Not ready to handle requests.", {})
      end
      return response(200, "json", json, {})
    end
  },

  ["api/play"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.set_property_bool, "pause", false)
      return handle_post(success, ret)
    end
  },

  ["api/pause"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.set_property_bool, "pause", true)
      return handle_post(success, ret)
    end
  },

  ["api/toggle_pause"] = {
    POST = function(_)
      local curr = mp.get_property_bool("pause")
      local _, success, ret = pcall(mp.set_property_bool, "pause", not curr)
      return handle_post(success, ret)
    end
  },

  ["api/fullscreen"] = {
    POST = function(_)
      local curr = mp.get_property_bool("fullscreen")
      local _, success, ret = pcall(mp.set_property_bool, "fullscreen", not curr)
      return handle_post(success, ret)
    end
  },

  ["api/seek"] = {
    POST = function(request)
      local t = request.param1
      local valid, msg = validate_number_param(t)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "seek", t)
      return handle_post(success, ret)
    end
  },

  ["api/add"] = {
    POST = function(request)
      local name, value = request.param1, request.param2
      local valid, msg = validate_name_param(name)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      if value ~= nil and value ~= '' then
        local valid, msg = validate_number_param(value)
        if not valid then
          return response(400, "json", utils.format_json({message = msg}), {})
        end
        local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', name, value)
        return handle_post(success, ret)
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', name)
      return handle_post(success, ret)
    end
  },

  ["api/cycle"] = {
    POST = function(request)
      local name, value = request.param1, request.param2
      local valid, msg = validate_name_param(name)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      if value ~= nil and value ~= '' then
        local valid, msg = validate_cycle_param(value)
        if not valid then
          return response(400, "json", utils.format_json({message = msg}), {})
        end
        local _, success, ret = pcall(mp.commandv, 'osd-msg', 'cycle', name, value)
        return handle_post(success, ret)
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'cycle', name)
      return handle_post(success, ret)
    end
  },

  ["api/multiply"] = {
    POST = function(request)
      local name, value = request.param1, request.param2
      local valid, msg = validate_name_param(name)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local valid, msg = validate_number_param(value)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'multiply', name, value)
      return handle_post(success, ret)
    end
  },

  ["api/set"] = {
    POST = function(request)
      local name, value = request.param1, request.param2
      local valid, msg = validate_name_param(name)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local valid, msg = validate_value_param(value)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'set', name, value)
      return handle_post(success, ret)
    end
  },

  ["api/toggle"] = {
    POST = function(request)
      local name = request.param1
      local valid, msg = validate_name_param(name)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local curr = mp.get_property_bool(name)
      local _, success, ret = pcall(mp.set_property_bool, name, not curr)
      return handle_post(success, ret)
    end
  },

  ["api/set_position"] = {
    POST = function(request)
      local t = request.param1
      local valid, msg = validate_number_param(t)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "seek", t, "absolute")
      return handle_post(success, ret)
    end
  },

  ["api/playlist_prev"] = {
    POST = function(_)
      local position = tonumber(mp.get_property("time-pos") or 0)
      if position > 1 then
        local _, success, ret = pcall(mp.commandv, 'osd-msg', "seek", -position)
        return handle_post(success, ret)
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "playlist-prev")
      return handle_post(success, ret)
    end
  },

  ["api/playlist_next"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "playlist-next")
      return handle_post(success, ret)
    end
  },

  ["api/playlist_jump"] = {
    POST = function(request)
      local p = request.param1
      local valid, msg = validate_number_param(p)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.set_property('playlist-pos', p))
      return handle_post(success, ret)
    end
  },

  ["api/playlist_remove"] = {
    POST = function(request)
      local p = request.param1
      local valid, msg = validate_number_param(p)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv('playlist-remove', p))
      return handle_post(success, ret)
    end
  },

  ["api/playlist_move"] = {
    POST = function(request)
      local s, t = request.param1, request.param2
      args = {s, t}
      for count = 1, 2 do
        local valid, msg = validate_number_param(args[count])
        if not valid then
          return response(400, "json", utils.format_json({message = msg}), {})
        end
      end
      local _, success, ret = pcall(mp.commandv('playlist-move', s, t))
      return handle_post(success, ret)
    end
  },

  ["api/playlist_move_up"] = {
    POST = function(request)
      local p = request.param1
      local valid, msg = validate_number_param(p)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      if p - 1 >= 0 then
        local _, success, ret = pcall(mp.commandv('playlist-move', p, p - 1))
        return handle_post(success, ret)
      end
      return response(400, "json", utils.format_json({message = msg}), {})
    end
  },

  ["api/playlist_shuffle"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.commandv('osd-msg', 'playlist-shuffle'))
      return handle_post(success, ret)
    end
  },

  ["api/loop_file"] = {
    POST = function(request)
      local mode = request.param1
      local valid, msg = validate_loop_param(mode, {"inf", "no"})
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.set_property('loop-file', mode))
      return handle_post(success, ret)
    end
  },

  ["api/loop_playlist"] = {
    POST = function(request)
      local mode = request.param1
      local valid, msg = validate_loop_param(mode, {"inf", "no", "force"})
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.set_property('loop-playlist', mode))
      return handle_post(success, ret)
    end
  },

  ["api/add_volume"] = {
    POST = function(request)
      local v = request.param1
      local valid, msg = validate_number_param(v)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', 'volume', v)
      return handle_post(success, ret)
    end
  },

  ["api/set_volume"] = {
    POST = function(request)
      local v = request.param1
      local valid, msg = validate_number_param(v)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'set', 'volume', v)
      return handle_post(success, ret)
    end
  },

  ["api/add_sub_delay"] = {
    POST = function(request)
      local sec = request.param1
      local valid, msg = validate_number_param(sec)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', 'sub-delay', sec)
      return handle_post(success, ret)
    end
  },

  ["api/set_sub_delay"] = {
    POST = function(request)
      local sec = request.param1
      local valid, msg = validate_number_param(sec)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'set', 'sub-delay', sec)
      return handle_post(success, ret)
    end
  },

  ["api/add_audio_delay"] = {
    POST = function(request)
      local sec = request.param1
      local valid, msg = validate_number_param(sec)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', 'audio-delay', sec)
      return handle_post(success, ret)
    end
  },

  ["api/set_audio_delay"] = {
    POST = function(request)
      local sec = request.param1
      local valid, msg = validate_number_param(sec)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'set', 'audio-delay', sec)
      return handle_post(success, ret)
    end
  },

  ["api/cycle_sub"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "cycle", "sub")
      return handle_post(success, ret)
    end
  },

  ["api/cycle_audio"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.commandv, 'osd-msg', "cycle", "audio")
      return handle_post(success, ret)
    end
  },

  ["api/cycle_audio_device"] = {
    POST = function(_)
      local audio_devices_list = get_audio_devices_list()
      local _, success, ret = pcall(mp.commandv, "osd-msg", "cycle_values", "audio-device", unpack(audio_devices_list))
      return handle_post(success, ret)
    end
  },

  ["api/speed_set"] = {
    POST = function(request)
      local speed = request.param1
      if speed == '' then
        speed = '1'
      end
      local valid, msg = validate_number_param(speed)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'set', 'speed', speed)
      return handle_post(success, ret)
    end
  },

  ["api/speed_adjust"] = {
    POST = function(request)
      local amount = request.param1
      local valid, msg = validate_number_param(amount)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'multiply', 'speed', amount)
      return handle_post(success, ret)
    end
  },

  ["api/add_chapter"] = {
    POST = function(request)
      local num = request.param1
      local valid, msg = validate_number_param(num)
      if not valid then
        return response(400, "json", utils.format_json({message = msg}), {})
      end
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'add', 'chapter', num)
      return handle_post(success, ret)
    end
  },

  ["api/quit"] = {
    POST = function(_)
      local _, success, ret = pcall(mp.commandv, 'osd-msg', 'quit')
      return handle_post(success, ret)
    end
  },

  ["api/loadfile"] = {
    POST = function(request)
      local uri, mode = request.param1, request.param2
      if uri == "" or type(uri) ~= "string" then
        return response(400, "json", utils.format_json({message = "No url provided!"}), {})
      end
      if mode ~= nil and
              mode ~= "" and
              mode ~= "replace" and
              mode ~= "append" and
              mode ~= "append-play"
      then
        return response(400, "json", utils.format_json({message = "Invalid mode: '" .. mode .. "'"}), {})
      end
      if mode == nil or mode == "" then
        mode = "replace"
      end
      local _, success, ret = pcall(mp.commandv, "loadfile", uri, mode)
      return handle_post(success, ret)
    end
  }
}

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

local function lines_from(file)
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

local function read_file(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local content = file:read "*a"
  file:close()
  return content
end

local function log_line(request, code, length)
  if not options.logging then
    return
  end

  local clientip = request.clientip or '-'
  local user = request.user or '-'
  local path = request.request or '-'
  local referer = request.referer or '-'
  local agent = request.agent or '-'
  local time = os.date('%d/%b/%Y:%H:%M:%S %z', os.time())
  mp.msg.info(('%s - %s [%s] "%s" %s %s "%s" "%s"'):format(
          clientip, user, time, path, code, length, referer, agent)
  )
end

local function log_osd(text)
  if not options.osd_logging then
    return
  end
  mp.osd_message(MSG_PREFIX .. text, 5)
end

local function handle_static_get(path)
  if path == "/" then
    path = 'index.html'
  end

  local content = read_file(options.static_dir .. "/" .. path)
  local extension = path:match("[^.]+$") or ""
  if content == nil or extension == nil then
    return response(404, "plain", "Error: Requested URL /"..path.." not found", {})
  end
  return response(200, extension, content, {})
end

local function is_authenticated(request, passwd)
  if not request.user or not request.password then
    return false
  end
  for _,line in ipairs(passwd) do
    if line == request.user..':'..request.password then
      return true
    end
  end
  return false
end

local function parse_path(raw_path)
  local path_components = string.gmatch(raw_path, "[^/]+")
  local path = path_components()
  if path == 'api' then
    path = path .. "/" .. path_components()
  end
  if path == 'api/loadfile' then
      -- The raw path itself might contain '/' which thus needs to be passed as a base64-encoded string.
      -- The base64-encoded path might itself contain '/', handling that by reversing the path for parsing.
      local rev_path = string.reverse(raw_path)
      param1 = dec64(string.reverse(string.sub(rev_path, string.find(rev_path, '/') + 1, string.find(rev_path, string.reverse('api/loadfile')) - 2))) or ""
      param2 = string.reverse(string.sub(rev_path, 1, string.find(rev_path, '/') - 1)) or ""
  else
      param1 = path_components() or ""
      param2 = path_components() or ""
  end

  return path, url.unescape(param1), url.unescape(param2)
end

local function call_endpoint(endpoint, req_method, request)
  if req_method == "OPTIONS" then
    return response(204, "plain", "", {Allow = table_key_concat(endpoint, ",") .. ",OPTIONS"})
  elseif endpoint[req_method] == nil then
    return response(
            405,
            "plain",
            "Error: Method not allowed",
            {Allow = table_key_concat(endpoint, ",") .. ",OPTIONS"}
    )
  end
  return endpoint[req_method](request)
end

local function handle_request(request, passwd)
  if passwd ~= nil then
    if not is_authenticated(request, passwd) then
      return response(401, "plain", "Authentication required.", {})
    end
  else
    request.user = nil
    request.password = nil
  end

  local endpoint = endpoints[request.path]
  if endpoint ~= nil then
    return call_endpoint(endpoint, request.method, request)
  end

  if request.method == "GET" then
    return handle_static_get(request.path)
  elseif file_exists(options.static_dir .. "/" .. request.path) and request.method == "OPTIONS" then
    return response(204, "plain", "", {Allow = "GET,OPTIONS"})
  elseif file_exists(options.static_dir .. "/" .. request.path) then
    return response(405, "plain", "Error: Method not allowed", {Allow = "GET,OPTIONS"})
  end
  return response(404, "plain", "Error: Requested URL /"..request.path.." not found", {})
end

local function new_request()
  return {
    agent = "",
    referer = "",
    user = nil,
    password = nil,
  }
end

local function parse_request(connection)
  local request = new_request()
  request.clientip = connection:getpeername()
  local line = connection:receive()
  if line == nil or line == "" then
    return
  end
  while line ~= nil and line ~= "" do
    if not request.request then
      local raw_request = string.gmatch(line, "%S+")
      request.request = line
      request.method = raw_request()
      request.path = "/"
      raw_path = string.sub(raw_request(), 2)
      if raw_path ~= "" then
        raw_path = raw_path:gsub("/+","/")
        request = url.parse(raw_path, request)
      end
    end
    if string.starts(string.lower(line), "user-agent") then
      request.agent = string.sub(line, 13)
    elseif string.starts(string.lower(line), "referer") then
      request.referer = string.sub(line, 10)
    elseif string.starts(string.lower(line), "authorization: basic ") then
      local auth64 = string.sub(line, 22)
      local auth_components = string.gmatch(dec64(auth64), "[^:]+")
      request.user = auth_components()
      request.password = auth_components()
    end
    line = connection:receive()
  end
  if request.method == "POST" then
    request.path, request.param1, request.param2 = parse_path(request.path)
  end
  return request
end

local function listen(server, passwd)
  local connection = server.server:accept()
  if connection == nil then
    return
  end

  local response = response(400, "plain", "Bad request!", {})

  local success, request = pcall(parse_request, connection)

  if success then
    if request == nil then
      return
    end
    response = handle_request(request, passwd)
  end

  connection:send(response.headers)
  connection:send(response.content)
  connection:close()
  log_line(request, response.code, response.content_length)
  return
end

local function get_passwd(path)
  if path ~= '' then
    if file_exists(path) then
      return lines_from(path)
    end
    msg = "Provided htpasswd_path \"" .. path .. "\" could not be found!"
    mp.msg.error("Error: " .. msg)
    message = function() log_osd(msg .. "\nwebui is disabled.") end
    mp.register_event("file-loaded", message)
    return 1
  end
end

local function get_ip(udp_method, check_ip)
  local s = udp_method()
  s:setpeername(check_ip, 80)
  local ip, _ = s:getsockname()
  return ip
end

local function get_server(ipv)
  local address = "0.0.0.0"
  local udp_method = socket.udp
  local check_ip = "91.198.174.192"
  local listen_format = "%s:%s"
  if ipv == 6 then
    address = "::0"
    udp_method = socket.udp6
    check_ip = "2620:0:862:ed1a::1"
    listen_format = "[%s]:%s"
  end

  local server = {}
  local s = socket.bind(address, options.port)
  if s == nil then
    return {}
  end

  server.server = s
  local ip = get_ip(udp_method, check_ip)

  server.listen = listen_format:format(ip, options.port)

  return {[address] = server}
end

local function init_servers()
  local servers = {}
  if not options.ipv4 and not options.ipv6 then
    mp.msg.error("Error: ipv4 and ipv6 is disabled!")
    return servers
  end
  if options.ipv6 then
    for k,v in pairs(get_server(6)) do servers[k] = v end
  end
  if options.ipv4 then
    for k,v in pairs(get_server(4)) do servers[k] = v end
  end

  return servers
end

if options.disable then
  mp.msg.info("disabled")
  message = function() log_osd("disabled") end
  mp.register_event("file-loaded", message)
  mp.register_event("file-loaded", function() mp.unregister_event(message) end)
  return
end

local passwd = get_passwd(options.htpasswd_path)
local servers = init_servers()

if passwd ~= 1 then
  if next(servers) == nil then
    error_msg = "Error: Couldn't spawn server on port " .. options.port
    message = function() mp.msg.error(error_msg); log_osd(error_msg) end
  else
    local listen_string = ""
    for _, server in pairs(servers) do
      server.server:settimeout(0)
      mp.add_periodic_timer(0.2, function() listen(server, passwd) end)
      if listen_string ~= "" then
        listen_string = listen_string .. "\n"
      end
      listen_string = listen_string .. server.listen
    end

    local startup_msg = ("v" .. VERSION .. "\n" .. listen_string)
    message = function() log_osd(startup_msg) end
    mp.msg.info(startup_msg)
    if passwd  ~= nil then
      mp.msg.info('Basic authentication is enabled.')
    end
  end

  mp.register_event("file-loaded", message)
  mp.register_event("file-loaded", function() mp.unregister_event(message) end)
end
