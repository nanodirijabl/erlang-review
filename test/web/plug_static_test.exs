defmodule ChattieWebPlugStaticTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Chattie.Web.PlugStatic.init([])

  test "successfully serve static html" do
    conn =
      :get
      |> conn("/", "")
      |> Chattie.Web.PlugStatic.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "<title>Chattie</title>"
    assert conn.resp_body =~ "<div id=\"messages-container\"></div>"
  end
end
