socket = require("socket")

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
      if (f ~= nil) then
        f(param);
        connection:send("HTTP/1.1 200 OK\n")
      else 
        connection:send("HTTP/1.1 404 Not Found\n")
      end

      connection:send("Connection: close\n\n")
      connection:close()
      return
    end

    if method == "GET" then
      local response = ""
      response = response.."HTTP/1.1 200 OK\n"
      response = response.."Content-Type: text/html; charset=UTF-8\n"
      response = response.."Connection: close\n\n"

      for l in io.lines("webui.html") do
        response = response..l
      end
      connection:send(response)
      connection:close()
      return
    end
    local line = connection:receive()
  end
  connection:close()
end

mp.add_periodic_timer(0.2, listen)
