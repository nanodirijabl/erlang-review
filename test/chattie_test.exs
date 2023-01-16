defmodule ChattieTest do
  use ExUnit.Case, async: true

  setup do
    start_supervised!({Registry, keys: :duplicate, name: ChattieTest.Registry})
    :ok
  end

  test "empty list of rooms" do
    assert Chattie.list_rooms(ChattieTest.Registry) == []
  end

  test "join lobby" do
    Chattie.join_room(ChattieTest.Registry, "lobby", nil)
    assert Chattie.list_rooms(ChattieTest.Registry) == ["lobby"]
  end

  test "join and leave same room" do
    Chattie.join_room(ChattieTest.Registry, "new_room", nil)
    Chattie.leave_room(ChattieTest.Registry, "new_room")
    assert Chattie.list_rooms(ChattieTest.Registry) == []
  end

  test "messaging between two users and one anonymous spectator" do
    Chattie.join_room(ChattieTest.Registry, "test_room", "Bob")
    assert_receive {:rooms_update, ["test_room"]}, 10

    joes_message = Chattie.Message.new_now(DateTime.utc_now(), "test_room", "Joe", "Hello, Mike")
    user_send_message(ChattieTest.Registry, joes_message)
    assert_receive {:new_message, ^joes_message}, 10

    mikes_message = Chattie.Message.new_now(DateTime.utc_now(), "test_room", "Mike", "Hello, Joe")
    setup_user_to_receive_message(ChattieTest.Registry, mikes_message, 10)
    user_send_message(ChattieTest.Registry, mikes_message)
    assert_receive {:report, {:new_message, ^mikes_message}}, 10
    assert_receive {:new_message, ^mikes_message}, 10
  end

  defp user_send_message(registry, send_message) do
    {:ok, _pid} =
      Task.start_link(fn ->
        Chattie.join_room(registry, send_message.room, send_message.username)
        Chattie.send_message(registry, send_message)
      end)
  end

  defp setup_user_to_receive_message(registry, receive_message, timeout) do
    parent = self()

    {:ok, _pid} =
      Task.start_link(fn ->
        Chattie.join_room(registry, receive_message.room, nil)

        report =
          receive do
            msg -> msg
          after
            timeout ->
              nil
          end

        send(parent, {:report, report})
      end)
  end
end
