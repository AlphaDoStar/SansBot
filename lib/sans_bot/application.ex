defmodule SansBot.Application do
  use IrisEx.Application,
    bots: [SansBot],
    ws_url: "ws://192.168.0.17:3000/ws",
    http_url: "http://192.168.0.17:3000",
    children: [SansBot.InteractiveShell]
end
