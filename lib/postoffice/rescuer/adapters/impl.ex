defmodule Postoffice.Rescuer.Adapters.Impl do
  @moduledoc false

  @callback list(host :: String) :: {:ok, list} | {:error, reason :: String}
end
