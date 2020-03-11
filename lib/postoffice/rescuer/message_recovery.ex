defmodule Postoffice.Rescuer.MessageRecovery do
  alias Postoffice.Rescuer.Client

  require Logger

  def run(host) do
    Logger.info("Started MessageRecovery for host #{host}")
    case Client.list(host) do
      {:ok, []} ->
        Logger.info("Undelivered messages not found on #{host}")
      {:ok, messages} ->
        messages
        |> Enum.each(fn message -> handle_message(message, host) end)
      {:error, []} ->
        Logger.info("Error on #{host} listing undelivering messages")
    end
  end

  defp handle_message(message, host) do
    {id, message_params} = Map.pop(message, "id")
    case Postoffice.receive_message(message_params) do
      {:ok, created_message} ->
        Logger.info("Successfully recovered message for topic #{created_message["topic"]} with public_id #{created_message["public_id"]}")
        Client.delete(host, id)
      {:relationship_does_not_exists, _errors} ->
        Logger.info("Trying to receive message for non existing topic #{message["topic"]}")
    end
  end
end
