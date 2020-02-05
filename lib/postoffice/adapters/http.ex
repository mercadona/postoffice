defmodule Postoffice.Adapters.Http do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(target, message) do
    Logger.info("Dispatching Http message to #{target}")
    %{payload: payload} = message

    HTTPoison.post(target, Poison.encode!(payload), [
      {"content-type", "application/json"}
    ])
  end
end
