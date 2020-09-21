defmodule Postoffice.Adapters.Http do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(
        id,
        %{
          "consumer_id" => consumer_id,
          "payload" => payload,
          "target" => target,
          "timeout" => timeout
        } = _args
      ) do
    Logger.info("Dispatching Http message to #{target}", publisher_id: consumer_id, id: id)

    HTTPoison.post(
      target,
      Poison.encode!(payload),
      [
        {"content-type", "application/json"},
        {"message-id", id}
      ],
      recv_timeout: timeout * 1_000
    )
  end
end
