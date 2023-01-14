defmodule Chattie.Web.CowboyWebsocket do
  @moduledoc """
  Websocket handler implementation for cowboy.
  See docs https://ninenines.eu/docs/en/cowboy/2.6/manual/cowboy_websocket/
  """

  @behaviour :cowboy_websocket

  alias Chattie.Message, as: Message

  defmodule State do
    @type t() :: %__MODULE__{username: binary, room: binary}
    defstruct username: nil, room: nil
  end

  @impl true
  def init(request, _state) do
    {:cowboy_websocket, request, %State{username: nil, room: nil}}
  end

  @impl true
  def websocket_init(%State{} = state) do
    Chattie.join_room(Chattie.RoomSubscription, "lobby")
    {:ok, %{state | room: "lobby"}}
  end

  @impl true
  def websocket_handle({:text, json_payload}, %State{} = state) do
    payload = Jason.decode!(json_payload)
    handle_chat_event(payload["data"]["event"], payload["data"], state)
  end

  defp handle_chat_event("changeUsername", %{"username" => username}, %State{} = state) do
    {:ok, %{state | username: username}}
  end

  defp handle_chat_event("joinRoom", %{"room" => room}, %State{room: old_room} = state) do
    Chattie.leave_room(Chattie.RoomSubscription, old_room)
    Chattie.join_room(Chattie.RoomSubscription, room)
    {:ok, %{state | room: room}}
  end

  defp handle_chat_event("sendMessage", _data, %State{username: nil} = state) do
    payload = Jason.encode!(%{"event" => "error", "errors" => ["Choose a username"]})
    {:reply, {:text, payload}, state}
  end

  defp handle_chat_event("sendMessage", _data, %State{room: nil} = state) do
    payload = Jason.encode!(%{"event" => "error", "errors" => ["You are not in a room"]})
    {:reply, {:text, payload}, state}
  end

  defp handle_chat_event("sendMessage", %{"text" => text}, %State{} = state) do
    Chattie.send_message(
      Chattie.RoomSubscription,
      Message.new_now(DateTime.utc_now(), state.room, state.username, text)
    )

    {:ok, state}
  end

  @impl true
  def websocket_info({:rooms_update, rooms}, %State{} = state) do
    payload = Jason.encode!(%{"event" => "roomsUpdate", "rooms" => rooms})
    {:reply, {:text, payload}, state}
  end

  @impl true
  def websocket_info({:new_message, %Message{room: room} = message}, %State{room: room} = state) do
    payload =
      Jason.encode!(%{
        "event" => "newMessage",
        "timestamp" => message.timestamp,
        "username" => message.username,
        "text" => message.text
      })

    {:reply, {:text, payload}, state}
  end

  @impl true
  def terminate(_reason, _partial_request, %State{room: room} = _state) do
    Chattie.leave_room(Chattie.RoomSubscription, room)
  end
end
