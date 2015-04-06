socket = require("socket")
require("webui-page")

host = "0.0.0.0"
port = "8000"
server = assert(socket.bind(host, port))
server:settimeout(0)

commands = {
  pause = function()
    local curr = mp.get_property_bool("pause")
    mp.set_property_bool("pause", not curr)
  end,

  seek = function(t)
    mp.command("seek "..t)
  end,

  volume = function(v)
    local curr = mp.get_property_number("volume")
    mp.set_property_number("volume", curr + v)
  end
}

function header(code, content_type)
  local h = ""
  if code == 200 then
    h = h.."HTTP/1.1 200 OK\n"

    if content_type == "html" then
      h = h.."Content-Type: text/html; charset=UTF-8\n"
    elseif content_type == "json" then
      h = h.."Content-Type: application/json; charset=UTF-8\n"
    end

  elseif code == 404 then
    h = h.."HTTP/1.1 404 Not Found\n"
  end

  return h.."Connection: close\n\n"
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
        connection:send(header(200, "html"))
      else 
        connection:send(header(404, nil))
      end

      connection:close()
      return

    elseif method == "GET" then
      local response = ""
      if (path == "") then
        connection:send(header(200, "html"))
        connection:send(page)
        connection:close()
        return

      else if (path == "status") then
          connection:send(header(200, "json"))
          local json = [[{"file":"]]..mp.get_property("path")..'",'
          json = json..'"length":"'..mp.get_property("length")..'",'
          json = json..'"pos":"'..mp.get_property("time-pos")..'",'
          json = json..'"volume":"'..mp.get_property("volume")..'"}'
          

          connection:send(json)
          connection:close()
          return
        else
          connection:send(header(404, nil))
          return
        end
      end
    end
  end
end
mp.add_periodic_timer(0.2, listen)
