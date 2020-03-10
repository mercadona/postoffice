defmodule Postoffice.Rescuer.Adapters.Impl do
  @moduledoc false

  @callback list(host :: String) :: {:ok, list} | {:error, reason :: String}
  @callback delete(host :: String, message_id :: Integer) :: {:ok, status :: Atom } | {:error, reason :: String}
end
