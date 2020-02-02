defmodule Postoffice.Adapters.Http do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(endpoint, message) do
    Logger.info("Dispatching Http message to #{endpoint}")
    %{payload: payload} = message

    HTTPoison.post(endpoint, Poison.encode!(payload), [
      {"content-type", "application/json"}
    ])
  end
end
