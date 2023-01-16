defmodule ChattieWebCowboyWebsocketTest do
  use ExUnit.Case, async: true

  test "initializing and terminating" do
    {:cowboy_websocket, _request, state, _opts} = Chattie.Web.CowboyWebsocket.init(%{}, [])
    assert %Chattie.Web.CowboyWebsocket.State{username: nil, room: nil} == state

    {:ok, state} = Chattie.Web.CowboyWebsocket.websocket_init(state)
    assert "lobby" == state.room

    assert :ok == Chattie.Web.CowboyWebsocket.terminate(:normal, %{}, state)
  end

  test "pushing rooms update to socket" do
    rooms = ["lobby", "test_room"]
    state = %Chattie.Web.CowboyWebsocket.State{}
    payload = Jason.encode!(%{"event" => "roomsUpdate", "rooms" => rooms})

    assert {:reply, {:text, payload}, state} ==
             Chattie.Web.CowboyWebsocket.websocket_info({:rooms_update, rooms}, state)
  end

  test "pushing new chat message to socket" do
    message = Chattie.Message.new_now(DateTime.utc_now(), "test_room", "Aleksey", "Hello")
    state = %Chattie.Web.CowboyWebsocket.State{room: message.room}

    payload =
      Jason.encode!(%{
        "event" => "newMessage",
        "timestamp" => message.timestamp,
        "username" => message.username,
        "text" => message.text
      })

    assert {:reply, {:text, payload}, state} ==
             Chattie.Web.CowboyWebsocket.websocket_info({:new_message, message}, state)
  end

  test "receiving username change from socket" do
    state = %Chattie.Web.CowboyWebsocket.State{username: "Ivan"}

    input_payload = """
    {
      "data": {
        "event": "changeUsername",
        "username": "Vasya"
      }
    }
    """

    assert {:ok, %Chattie.Web.CowboyWebsocket.State{username: "Vasya"}} ==
             Chattie.Web.CowboyWebsocket.websocket_handle({:text, input_payload}, state)
  end

  test "receiving user joining room event from socket" do
    state = %Chattie.Web.CowboyWebsocket.State{room: "lobby"}

    input_payload = """
    {
      "data": {
        "event": "joinRoom",
        "room": "general"
      }
    }
    """

    assert {:ok, %Chattie.Web.CowboyWebsocket.State{room: "general"}} ==
             Chattie.Web.CowboyWebsocket.websocket_handle({:text, input_payload}, state)
  end

  test "receiving new message event from socket" do
    state = %Chattie.Web.CowboyWebsocket.State{room: "lobby", username: "Aleksey"}

    input_payload = """
    {
      "data": {
        "event": "sendMessage",
        "text": "Hello."
      }
    }
    """

    assert {:ok, %Chattie.Web.CowboyWebsocket.State{room: "lobby", username: "Aleksey"}} ==
             Chattie.Web.CowboyWebsocket.websocket_handle({:text, input_payload}, state)
  end

  test "receiving new message event from socket when room is not joined" do
    state = %Chattie.Web.CowboyWebsocket.State{username: "Aleksey"}

    input_payload = """
    {
      "data": {
        "event": "sendMessage",
        "text": "Hello."
      }
    }
    """

    reply_payload = "{\"errors\":[\"You are not in a room\"],\"event\":\"error\"}"

    assert {:reply, {:text, reply_payload},
            %Chattie.Web.CowboyWebsocket.State{username: "Aleksey"}} ==
             Chattie.Web.CowboyWebsocket.websocket_handle({:text, input_payload}, state)
  end

  test "receiving new message event from socket when username is not set" do
    state = %Chattie.Web.CowboyWebsocket.State{room: "lobby"}

    input_payload = """
    {
      "data": {
        "event": "sendMessage",
        "text": "Hello."
      }
    }
    """

    reply_payload = "{\"errors\":[\"Choose a username\"],\"event\":\"error\"}"

    assert {:reply, {:text, reply_payload}, %Chattie.Web.CowboyWebsocket.State{room: "lobby"}} ==
             Chattie.Web.CowboyWebsocket.websocket_handle({:text, input_payload}, state)
  end
end
