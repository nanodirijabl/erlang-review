defmodule Chattie.Web.PlugStatic do
  @moduledoc false

  import Plug.Conn

  # Recompile and reload manually, won't see changes in html file
  @static_html File.read!("priv/app.html")

  def init(options) do
    options
  end

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, @static_html)
  end
end
