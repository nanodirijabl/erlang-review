defmodule Chattie do
  @moduledoc """
  Room management and user chat implementation via `Registry`.

  TODO: make it a behaviour and decouple implementation from interface.
  """
  @moduledoc since: "0.0.1"

  @doc """
  Lists all existing rooms.
  """
  @spec list_rooms(atom) :: list(binary)
  def list_rooms(registry) do
    registry
    |> Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.uniq()
  end

  @doc """
  Joins room via implicit subscription of current process to room as key in
  `Registry` with duplicates.
  """
  @spec join_room(atom, binary) :: :ok
  def join_room(registry, room) do
    # Count matching room name (as registry entry key)
    room_existed? =
      0 != Registry.count_select(registry, [{{:"$1", :_, :_}, [{:==, :"$1", room}], [true]}])

    {:ok, _pid} = Registry.register(registry, room, [])

    unless room_existed? do
      registry
      |> list_all_subscribers()
      |> Enum.each(&send(&1, {:rooms_update, list_rooms(registry)}))
    end

    :ok
  end

  defp list_all_subscribers(registry) do
    registry
    |> Registry.select([{{:_, :"$1", :_}, [], [:"$1"]}])
    |> Enum.uniq()
  end

  @doc """
  Current processs leaves room and unsubscribes from given key/room in
  `Registry`.
  """
  @spec leave_room(atom, binary) :: :ok
  def leave_room(registry, room) do
    Registry.unregister(registry, room)
  end

  @doc """
  Sends message and broadcasts it to others in that room.
  Since it relies upon `Registry.dispatch/4`, so sending is performed by
  *this* process.
  """
  @spec send_message(atom, Chattie.Message.t()) :: :ok
  def send_message(registry, %Chattie.Message{room: room} = message) do
    Registry.dispatch(registry, room, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:new_message, message})
    end)
  end
end
