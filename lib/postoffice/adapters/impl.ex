defmodule Postoffice.Adapters.Impl do
  @moduledoc false

  alias Postoffice.Adapters.Message

  @callback publish(String, Message) :: {:ok, Message} | {:error, reason :: String}
end
