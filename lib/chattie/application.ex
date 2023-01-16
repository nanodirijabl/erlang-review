defmodule Chattie.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @port 8888

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Chattie.Worker.start_link(arg)
      # {Chattie.Worker, arg}
      Chattie.WatchdogBot,
      {Registry,
       keys: :duplicate, name: Chattie.RoomSubscription, listeners: [Chattie.WatchdogBot]},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Chattie.Web.PlugStatic,
        options: [port: @port, dispatch: dispatch()]
      )
    ]

    Logger.info("Starting web server http://localhost:#{@port}")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chattie.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      # See cowboy docs
      # ... %% {HostMatch, list({PathMatch, Handler, InitialState})}
      {:_,
       [
         {"/websocket", Chattie.Web.CowboyWebsocket, []},
         {:_, Plug.Cowboy.Handler, {Chattie.Web.PlugStatic, []}}
       ]}
    ]
  end
end
