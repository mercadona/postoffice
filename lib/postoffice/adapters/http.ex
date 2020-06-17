defmodule Postoffice.Adapters.Http do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(publisher, message) do
    Logger.info("Dispatching Http message to #{publisher.target}")
    %{payload: payload} = message

    HTTPoison.post(
      publisher.target,
      Poison.encode!(payload),
      [
        {"content-type", "application/json"},
        {"message-id", message.id}
      ],
      [
        recv_timeout: publisher.seconds_timeout * 1_000
      ]
    )
  end
end
