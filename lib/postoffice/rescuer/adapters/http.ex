defmodule Postoffice.Rescuer.Adapters.Http do
  require Logger

  @behaviour Postoffice.Rescuer.Adapters.Impl

  @impl true
  def list(host) do
    Logger.info("Listing undelivered messages from #{host}")
    HTTPoison.get(host)
  end

  @impl true
  def delete(host, message_id) do
    build_message_path(host, message_id)
    |> HTTPoison.delete()
  end

  defp build_message_path(host, message_id) do
    host <> message_id <> "/"
  end
end
