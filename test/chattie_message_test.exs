defmodule ChattieMessageTest do
  use ExUnit.Case, async: true

  test "new message with current timestamp" do
    date_time = DateTime.utc_now()
    message = Chattie.Message.new_now(date_time, "test_room", "Bob", "Hello, Joe. Hello, Mike.")
    timestamp = DateTime.to_iso8601(date_time)

    assert %Chattie.Message{
             timestamp: timestamp,
             room: "test_room",
             username: "Bob",
             text: "Hello, Joe. Hello, Mike."
           } == message
  end
end
