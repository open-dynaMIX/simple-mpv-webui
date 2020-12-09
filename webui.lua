require 'mp.options'
require 'mp.msg'
utils = require 'mp.utils'
local socket = require("socket")
local dec64 = require("mime").decode("base64")
local url = require("socket.url")

local MSG_PREFIX = "[webui] "
local VERSION = "2.1.0"

function string.starts(String, Start)
  return string.sub(String,1,string.len(Start))==Start
end

local function script_path()
  local str = debug.getinfo(2, "S").source
  if string.starts(str,"@") then
    str = str:sub(2)
  end
  return str:match("(.*/)")
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

local function validate_number_param(param)
  if not tonumber(param) then
    return false, 'Parameter needs to be an integer or float'
  else
    return true, nil
  end
end

local function validate_name_param(param)
  if not string.match(param, '^[a-z0-9/-]+$') then
    return false, 'Parameter name contains invalid characters'
  else
    return true, nil
  end
end

local function validate_value_param(param)
  if not string.match(param, '^%g+$') then
    return false, 'Parameter value contains invalid characters'
  else
    return true, nil
  end
end

local function validate_cycle_param(param)
  if param ~= 'up' and param ~= 'down' then
    return false, 'Cycle paramater is not "up" or "down"'
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
    return false, "Invalid parameter!"
  end
  return true, nil
end

local function get_audio_devices()
  local function add_device(d, active, ad)
    ad[#ad+1] = {
          name = d.name,
          description = d.description,
          active = d.name == active
    }
    return ad
  end
  local active_device = mp.get_property_native("audio-device")
  local audio_devices = {}
  for _, device in pairs(mp.get_property_native("audio-device-list")) do
    if options.audio_devices ~= "" then
      if options.audio_devices == device.name
              or string.find(options.audio_devices, " "..device.name, 1, true)
              or string.find(options.audio_devices, device.name.." ", 1, true)
      then
        audio_devices = add_device(
                device,
                active_device,
                audio_devices
        )
      end
    else
      audio_devices = add_device(
                device,
                active_device,
                audio_devices
        )
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
    return pcall(mp.commandv, 'osd-msg', "seek", t)
  end,

  add = function(name, value)
    local valid, msg = validate_name_param(name)
    if not valid then
      return true, false, msg
    end
    if value ~= nil and value ~= '' then
      local valid, msg = validate_number_param(value)
      if not valid then
        return true, false, msg
      end
      return pcall(mp.commandv, 'osd-msg', 'add', name, value)
    else
      return pcall(mp.commandv, 'osd-msg', 'add', name)
    end
  end,

  cycle = function(name, value)
    local valid, msg = validate_name_param(name)
    if not valid then
      return true, false, msg
    end
    if value ~= nil and value ~= '' then
      local valid, msg = validate_cycle_param(value)
      if not valid then
        return true, false, msg
      end
      return pcall(mp.commandv, 'osd-msg', 'cycle', name, value)
    else
      return pcall(mp.commandv, 'osd-msg', 'cycle', name)
    end
  end,

  multiply = function(name, value)
    local valid, msg = validate_name_param(name)
    if not valid then
      return true, false, msg
    end
    local valid, msg = validate_number_param(value)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'multiply', name, value)
  end,

  set = function(name, value)
    local valid, msg = validate_name_param(name)
    if not valid then
      return true, false, msg
    end
    local valid, msg = validate_value_param(value)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'set', name, value)
  end,

  toggle = function(name)
    local valid, msg = validate_name_param(name)
    if not valid then
      return true, false, msg
    end
    local curr = mp.get_property_bool(name)
    return pcall(mp.set_property_bool, name, not curr)
  end,

  set_position = function(t)
    local valid, msg = validate_number_param(t)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', "seek", t, "absolute")
  end,

  playlist_prev = function()
    local position = tonumber(mp.get_property("time-pos") or 0)
    if position > 1 then
      return pcall(mp.commandv, 'osd-msg', "seek", -position)
    else
      return pcall(mp.commandv, 'osd-msg', "playlist-prev")
    end
  end,

  playlist_next = function()
    return pcall(mp.commandv, 'osd-msg', "playlist-next")
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
    return pcall(mp.commandv('osd-msg', 'playlist-shuffle'))
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
    return pcall(mp.commandv, 'osd-msg', 'add', 'volume', v)
  end,

  set_volume = function(v)
    local valid, msg = validate_number_param(v)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'set', 'volume', v)
  end,

  add_sub_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'add', 'sub-delay', sec)
  end,

  set_sub_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'set', 'sub-delay', sec)
  end,

  add_audio_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'add', 'audio-delay', sec)
  end,

  set_audio_delay = function(sec)
    local valid, msg = validate_number_param(sec)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'set', 'audio-delay', sec)
  end,

  cycle_sub = function()
    return pcall(mp.commandv, 'osd-msg', "cycle", "sub")
  end,

  cycle_audio = function()
    return pcall(mp.commandv, 'osd-msg', "cycle", "audio")
  end,

  cycle_audio_device = function()
    local audio_devices_list = get_audio_devices_list()
    return pcall(mp.commandv, "osd-msg", "cycle_values", "audio-device", unpack(audio_devices_list))
  end,

  speed_set = function(speed)
    if speed == '' then
      speed = '1'
    end
    local valid, msg = validate_number_param(speed)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'set', 'speed', speed)
  end,

  speed_adjust = function(amount)
    local valid, msg = validate_number_param(amount)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'multiply', 'speed', amount)
  end,

  add_chapter = function(num)
    local valid, msg = validate_number_param(num)
    if not valid then
      return true, false, msg
    end
    return pcall(mp.commandv, 'osd-msg', 'add', 'chapter', num)
  end,

  quit = function()
    return pcall(mp.commandv, 'osd-msg', 'quit')
  end,

  loadfile = function(uri, mode)
    if uri == nil or type(uri) ~= "string" then
      return true, false, "No url provided!"
    end
    if mode ~= nil and
            mode ~= "" and
            mode ~= "replace" and
            mode ~= "append" and
            mode ~= "append-play"
    then
      print('Invalid mode: "' .. mode .. '"')
      return true, false, "Invalid mode: '" .. mode .. "'"
    end
    if mode == nil or mode == "" then
      mode = "replace"
    end
    return pcall(mp.commandv, "loadfile", uri, mode)
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
  local status_headers = {
    [200] = "OK",
    [400] = "Bad Request",
    [401] = 'Unauthorized\nWWW-Authenticate: Basic realm="Simple MPV WebUI',
    [404] = "Not Found",
    [405] = "Method Not Allowed\nAllow: GET,POST",
    [503] = "Service Unavailable"
  }

  return "HTTP/1.1 " .. tostring(code) .. " " .. status_headers[code] ..
         '\nAccess-Control-Allow-Origin: *\nContent-Type: ' .. content_type ..
         '\nContent-Length: ' .. content_length .. '\nServer: simple-mpv-webui\nConnection: close\n\n'
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
  local user = request.user or '-'
  local path = request.request or '-'
  local referer = request.referer or '-'
  local agent = request.agent or '-'
  local time = os.date('%d/%b/%Y:%H:%M:%S %z', os.time())
  mp.msg.info(
    clientip..' - '..user..' ['..time..'] "'..path..'" '..code..' '..length..' "'..referer..'" "'..agent..'"')
end

local function log_osd(text)
  if not options.osd_logging then
    return
  end
  mp.osd_message(MSG_PREFIX .. text, 5)
end

local function build_status_response()
  local values = {
    ["audio-delay"] = mp.get_property_osd("audio-delay") or '',
    ["audio-devices"] = get_audio_devices(),
    chapter = mp.get_property_native("chapter") or 0,
    chapters = mp.get_property_native("chapters") or '',
    ["chapter-list"] = mp.get_property_native("chapter-list") or '',
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
    ["webui-version"] = VERSION,
    volume = mp.get_property_native("volume") or '',
    ["volume-max"] = mp.get_property_native("volume-max") or ''
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

  param1 = url.unescape(param1)
  param2 = url.unescape(param2)

  local f = commands[command]
  if f ~= nil then
    local _, success, ret = f(param1, param2)
    if success and ret == nil then
      ret = "success"
    end
    response_json = utils.format_json({message = ret})
    if success then
      return 200, get_content_type('json'), response_json
    else
      return 400, get_content_type('json'), response_json
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
  if path == "" then
    path = 'index.html'
  end

  local content = read_file(options.static_dir .. "/" .. path)
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
  else
    request.user = nil
    request.password = nil
  end
  if request.method == "POST" then
    return handle_post(request.path)

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
  return request
end

local function listen(server, passwd)
  local connection = server.server:accept()
  if connection == nil then
    return
  end

  local code = 400
  local content_type = get_content_type("plain")
  local content = "Bad request!"

  local success, request = pcall(parse_request, connection)

  if success then
    if request == nil then
      return
    end
    code, content_type, content = handle_request(request, passwd)
  end

  connection:send(header(code, content_type, #content))
  connection:send(content)
  connection:close()
  log_line(request, code, #content)
  return
end

local function get_passwd(path)
  if path ~= '' then
    if file_exists(path) then
      return lines_from(path)
    else
      msg = "Provided htpasswd_path \"" .. path .. "\" could not be found!"
      mp.msg.error("Error: " .. msg)
      message = function() log_osd(msg .. "\nwebui is disabled.") end
      mp.register_event("file-loaded", message)
      return 1
    end
  end
end

local function get_ip(udp_method, check_ip)
  local s = udp_method()
  s:setpeername(check_ip, 80)
  local ip, _ = s:getsockname()
  return ip
end

local function init_servers()
  local servers = {}
  if not options.ipv4 and not options.ipv6 then
    mp.msg.error("Error: ipv4 and ipv6 is disabled!")
    return servers
  end
  if options.ipv6 then
    local address = '::0'
    servers[address] = {server = socket.bind(address, options.port)}
    local ip = get_ip(socket.udp6, "2620:0:862:ed1a::1")
    servers[address].listen = "[" .. ip .. "]:" .. options.port
  end
  if options.ipv4 then
    local address = '0.0.0.0'
    servers[address] = {server = socket.bind(address, options.port)}
    local ip = get_ip(socket.udp, "91.198.174.192")
    servers[address].listen = ip .. ":" .. options.port
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
