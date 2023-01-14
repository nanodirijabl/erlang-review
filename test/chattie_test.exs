defmodule ChattieTest do
  use ExUnit.Case
  doctest Chattie

  test "greets the world" do
    assert Chattie.hello() == :world
  end
end
