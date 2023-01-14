defmodule Chattie.Message do
  @typedoc """
  Represents chat message
  """
  @type t() :: %__MODULE__{
          room: binary(),
          timestamp: binary(),
          username: binary(),
          text: binary()
        }
  @enforce_keys [:room, :timestamp, :username, :text]
  defstruct [:room, :timestamp, :username, :text]

  @spec new_now(DateTime.t(), binary(), binary(), binary()) :: Chattie.Message.t()
  def new_now(%DateTime{} = date_time, room, username, text) do
    %__MODULE__{
      room: room,
      timestamp: DateTime.to_iso8601(date_time),
      username: username,
      text: text
    }
  end
end
