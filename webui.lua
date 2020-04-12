require 'mp.options'
require 'mp.msg'
utils = require 'mp.utils'
local socket = require("socket")
local dec64 = require("mime").decode("base64")
local url = require("socket.url")

local MSG_PREFIX = "[webui] "
local VERSION = "0.3.1"

local options = {
  port = 8080,
  disable = false,
  logging = false,
  ipv4 = true,
  ipv6 = true,
  audio_devices = '',
}
read_options(options, "webui")

local function validate_number_param(param)
  if not tonumber(param) then
    return false, 'Parameter needs to be an integer or float'
  else
    return true, nil
  end
end

local function validate_loop_param(param, valid_table)
  for _, value in pairs(valid_table) do
    if value == param then
      return true, nil
    end
  end
  valid, msg = validate_number_param(param)
  if not valid then
    return false, "Invalid parameter!p"
  end
  return true, nil
end

local commands = {
  play = function()
    return pcall(mp.set_property_bool, "pause", false)
  end,

  pause = function()
    return pcall(mp.set_property_bool, "pause", true)
  end,

  toggle_pause = function()
    local curr = mp.get_property_bool("pause")
    return pcall(mp.set_property_bool, "pause", not curr)
  end,

  fullscreen = function()
    local curr = mp.get_property_bool("fullscreen")
    return pcall(mp.set_property_bool, "fullscreen", not curr)
  end,

  seek = function(t)
    local valid, msg = validate_number_param(t)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, "seek "..t)
  end,

  set_position = function(t)
    local valid, msg = validate_number_param(t)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, "seek "..t.." absolute")
  end,

  playlist_prev = function()
    local position = tonumber(mp.get_property("time-pos") or 0)
    if position > 1 then
      return pcall(mp.command, "seek "..-position)
    else
      return pcall(mp.command, "playlist-prev")
    end
  end,

  playlist_next = function()
    return pcall(mp.command, "playlist-next")
  end,

  playlist_jump = function(p)
    local valid, msg = validate_number_param(p)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.set_property('playlist-pos', p))
  end,

  playlist_remove = function(p)
    local valid, msg = validate_number_param(p)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv('playlist-remove', p))
  end,

  playlist_move = function(s, t)
    args = {s, t}
    for count = 1, 2 do
      local valid, msg = validate_number_param(args[count])
      if not valid then
        return true, false, msg
      end
    end
    return pcall(mp.commandv('playlist-move', s, t))
  end,

  playlist_move_up = function(p)
    local valid, msg = validate_number_param(p)
    if not valid then
      return true, false, msg
    end
    if p - 1 >= 0 then
      return pcall(mp.commandv('playlist-move', p, p - 1))
    else
      return true, true, true
    end
  end,

  playlist_shuffle = function()
    return pcall(mp.command('playlist-shuffle'))
  end,

  loop_file = function(mode)
    local valid, msg = validate_loop_param(mode, {"inf", "no"})
    if not valid then
      return true, false, msg
    end
    return pcall(mp.set_property('loop-file', mode))
  end,

  loop_playlist = function(mode)
    local valid, msg = validate_loop_param(mode, {"inf", "no", "force"})
    if not valid then
      return true, false, msg
    end
    return pcall(mp.set_property('loop-playlist', mode))
  end,

  add_volume = function(v)
    local valid, msg = validate_number_param(v)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'add volume '..v)
  end,

  set_volume = function(v)
    local valid, msg = validate_number_param(v)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'set volume '..v)
  end,

  add_sub_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'add sub-delay '..sec)
  end,

  set_sub_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'set sub-delay '..sec)
  end,

  add_audio_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'add audio-delay '..sec)
  end,

  set_audio_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'set audio-delay '..sec)
  end,

  cycle_sub = function()
    return pcall(mp.command, "cycle sub")
  end,

  cycle_audio = function()
    return pcall(mp.command, "cycle audio")
  end,

  cycle_audio_device = function()
    return pcall(mp.command, "cycle_values audio-device " .. options.audio_devices)
  end,

  add_chapter = function(num)
    local valid, msg = validate_number_param(num)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.command, 'add chapter '..num)
  end
}

local function get_content_type(file_type)
  if file_type == 'html' then
    return 'text/html; charset=UTF-8'
  elseif file_type == 'plain' then
    return 'text/plain; charset=UTF-8'
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
  elseif file_type == 'webmanifest' then
    return 'application/manifest+json'
  end
end

local function header(code, content_type, content_length)
  local common = '\nAccess-Control-Allow-Origin: *'..
          '\nContent-Type: '..content_type..
          '\nContent-Length: '..content_length..
          '\nServer: simple-mpv-webui'..
          '\nConnection: close\n\n'
  if code == 200 then
    return 'HTTP/1.1 200 OK'..common
  elseif code == 400 then
    return 'HTTP/1.1 400 Bad Request'..common
  elseif code == 401 then
    return 'HTTP/1.1 401 Unauthorized\nWWW-Authenticate: Basic realm="Simple MPV WebUI"'..common
  elseif code == 404 then
    return 'HTTP/1.1 404 Not Found'..common
  elseif code == 405 then
    return 'HTTP/1.1 405 Method Not Allowed\nAllow: GET,POST'..common
  elseif code == 503 then
    return 'HTTP/1.1 503 Service Unavailable'..common
  end
end

function string.starts(String, Start)
  return string.sub(String,1,string.len(Start))==Start
end

local function concatkeys(tab, sep)
  local inter = {}
  for key,_ in pairs(tab) do
    inter[#inter+1] = key
  end
  return table.concat(inter, sep)
end

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

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
  local path = request.request or '-'
  local referer = request.referer or '-'
  local agent = request.agent or '-'
  local time = os.date('%d/%b/%Y:%H:%M:%S %z', os.time())
  mp.msg.info(
    clientip..' - - ['..time..'] "'..path..'" '..code..' '..length..' "'..referer..'" "'..agent..'"')
end

local function is_audio_supported()
  devices = mp.get_property_native('audio-device-list')
  if devices[1].name == "auto" and not devices[2] then
    return false
  end
  return true
end

local function build_status_response()
  local values = {
    ["audio-delay"] = mp.get_property_osd("audio-delay") or '',
    ["audio-support"] = is_audio_supported(),
    chapter = mp.get_property_native("chapter") or 0,
    chapters = mp.get_property_native("chapters") or '',
    duration = mp.get_property("duration") or '',
    filename = mp.get_property('filename') or '',
    fullscreen = mp.get_property_native("fullscreen"),
    ["loop-file"] = mp.get_property_native("loop-file"),
    ["loop-playlist"] = mp.get_property_native("loop-playlist"),
    metadata = mp.get_property_native("metadata") or '',
    pause = mp.get_property_native("pause"),
    playlist = mp.get_property_native("playlist") or '',
    position = mp.get_property("time-pos") or '',
    remaining = mp.get_property("playtime-remaining") or '',
    ["sub-delay"] = mp.get_property_osd("sub-delay") or '',
    ["track-list"] = mp.get_property_native("track-list") or '',
    volume = mp.get_property("volume") or '',
    ["volume-max"] = mp.get_property("volume-max") or ''
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
    if v == '' then
      mp.msg.log("WARN", 'Could not fetch "'.. k .. '" from mpv.')
      fail = true
    end
  end

  if fail then
      mp.msg.log("WARN", 'This is normal during startup.')
      return false
  end

  return utils.format_json(values)
end

local function handle_post(path)
  local components = string.gmatch(path, "[^/]+")
  local api_prefix = components()
  if api_prefix ~= 'api' then
    return 404, get_content_type('plain'), "Error: Requested URL /"..path.." not found"
  end
  local command = components()
  local param1 = components() or ""
  local param2 = components() or ""

  local f = commands[command]
  if f ~= nil then
    local _, err, ret = f(param1, param2)
    if err then
      return 200, get_content_type('json'), '{"message": "success"}'
    else
      return 400, get_content_type('json'), '{"message": "'..ret..'"}'
    end
  else
    return 404, get_content_type('plain'), "Error: Requested URL /"..path.." not found"
  end
end

local function handle_status_get()
  local json = build_status_response()
  if not json then
    return 503, get_content_type('plain'), "Error: Not ready to handle requests."
  else
    return 200, get_content_type("json"), json
  end
end

local function handle_static_get(path)
  if string.find(path, '%.%./') then
    return nil, nil
  end
  if path == "" then
    path = 'index.html'
  end

  local content = read_file(script_path()..'webui-page/'..path)
  local extension = path:match("[^.]+$") or ""
  local content_type = get_content_type(extension)
  if content == nil or content_type == nil then
    return 404, get_content_type('plain'), "Error: Requested URL /"..path.." not found"
  else
    return 200, content_type, content
  end
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

local function handle_request(request, passwd)
  if passwd ~= nil then
    if not is_authenticated(request, passwd) then
      return 401, get_content_type('plain'), "Authentication required."
    end
  end
  if request.method == "POST" then
    return handle_post(request['path'])

  elseif request.method == "GET" then
    if request.path == "api/status" or request.path == "api/status/" then
      return handle_status_get()
    else
      return handle_static_get(request.path)
    end
  else
    return 405, get_content_type('plain'), "Error: Method not allowed"
  end
end

local function parse_request(connection)
  local request = {}
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
      request.path = ""
      raw_path = string.sub(raw_request(), 2)
      if raw_path ~= "" then
        request = url.parse(raw_path, request)
      end
    end
    if string.starts(line, "User-Agent") then
      request.agent = string.sub(line, 13)
    elseif string.starts(line, "Referer") then
      request.referer = string.sub(line, 10)
    elseif string.starts(line, "Authorization: Basic ") then
      local auth64 = string.sub(line, 22)
      local auth_components = string.gmatch(dec64(auth64), "[^:]+")
      request.user = auth_components()
      request.password = auth_components()
    end
    line = connection:receive()
  end
  return request
end

local function listen(server, passwd)
  local connection = server:accept()
  if connection == nil then
    return
  end

  local request = parse_request(connection)
  if request == nil then
    return
  end
  local code, content_type, content = handle_request(request, passwd)

  connection:send(header(code, content_type, #content))
  connection:send(content)
  connection:close()
  log_line(request, code, #content)
  return
end

local function get_passwd()
  if file_exists(script_path()..".htpasswd") then
    return lines_from(script_path()..".htpasswd")
  end
end

local function init_servers()
  local servers = {}
  if not options.ipv4 and not options.ipv6 then
    mp.msg.error("Error: ipv4 and ipv6 is disabled!")
    return servers
  end
  if options.ipv6 then
    local address = '::0'
    servers[address] = socket.bind(address, options.port)
  end
  if options.ipv4 then
    local address = '0.0.0.0'
    servers[address] = socket.bind(address, options.port)
  end

  return servers
end

if options.audio_devices == '' then
  for _, device in pairs(mp.get_property_native("audio-device-list")) do
    options.audio_devices = options.audio_devices .. " " .. device.name
  end
end

if options.disable then
  message = function() mp.osd_message(MSG_PREFIX .. "disabled", 5) end
  return
end

local passwd = get_passwd()
local servers = init_servers()

if next(servers) == nil then
  error_msg = "Error: Couldn't spawn server on port " .. options.port
  message = function() mp.msg.error(error_msg, 5) end
else
  for _, server in pairs(servers) do
    server:settimeout(0)
    mp.add_periodic_timer(0.2, function() listen(server, passwd) end)
  end
  startup_msg = MSG_PREFIX .. "v" .. VERSION .. "\nServing on " .. concatkeys(servers, ':' .. options.port .. ' and ') .. ":" .. options.port
  message = function() mp.osd_message(startup_msg, 5) end
  mp.msg.info(startup_msg)
  if passwd  ~= nil then
    mp.msg.info('Found .htpasswd file. Basic authentication is enabled.')
  end
end

mp.register_event("file-loaded", message)
mp.register_event("file-loaded", function() mp.unregister_event(message) end)
