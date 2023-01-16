defmodule Chattie.WatchdogBot do
  @moduledoc """
  Chat bot.
  It is subscribed to changes in chat rooms registry.
  """

  use GenServer

  @username "WatchdogBot"

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init([]) do
    Process.send_after(self(), :tick, tick_timeout())
    {:ok, []}
  end

  defp tick_timeout do
    # Random miliseconds 1_000..15_000
    :rand.uniform(15) * 1000
  end

  @impl true
  def handle_info({:register, Chattie.RoomSubscription, room, _user_pid, value}, state) do
    user_joined =
      case value do
        %{username: nil} -> "Someone"
        %{username: name} -> "@" <> name
      end

    message =
      Chattie.Message.new_now(
        DateTime.utc_now(),
        room,
        @username,
        "#{user_joined} joined ##{room}"
      )

    Chattie.send_message(Chattie.RoomSubscription, message)
    {:noreply, state}
  end

  @impl true
  def handle_info({:unregister, Chattie.RoomSubscription, room, _user_pid}, state) do
    message =
      Chattie.Message.new_now(DateTime.utc_now(), room, @username, "Someone left ##{room}")

    Chattie.send_message(Chattie.RoomSubscription, message)
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    Chattie.RoomSubscription
    |> Chattie.list_rooms()
    |> send_random_message()

    Process.send_after(self(), :tick, tick_timeout())
    {:noreply, state}
  end

  defp send_random_message([]) do
    :ok
  end

  defp send_random_message(available_rooms) do
    room = Enum.random(available_rooms)
    message = Chattie.Message.new_now(DateTime.utc_now(), room, @username, homer_quote())
    Chattie.send_message(Chattie.RoomSubscription, message)
  end

  defp homer_quote do
    Enum.random([
      "Of all creatures that breathe and move upon the earth, nothing is bred that is weaker than man.",
      "…There is the heat of Love, the pulsing rush of Longing, the lover’s whisper, irresistible—magic to make the sanest man go mad.",
      "Any moment might be our last. Everything is more beautiful because we're doomed. You will never be lovelier than you are now. We will never be here again.",
      "Hateful to me as the gates of Hades is that man who hides one thing in his heart and speaks another.",
      "There is a time for many words, and there is also a time for sleep."
    ])
  end
end
