defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(subscription_to_topic) do
    case ingest_messages(subscription_to_topic) do
      {:ok, :empty} -> {:ok}
      {:ok, ackIds} ->
        PubSubClient.confirm(ackIds)
    end
  end

  defp ingest_messages(subscription_to_topic) do
      case PubSubClient.get(subscription_to_topic) do
        {:ok, :empty} -> {:ok, :empty}
        {:ok, messages} ->
          ackIds = Enum.map(messages, fn message ->
            {:ok, _message} = Postoffice.receive_message(message)
            message["ackId"]
          end)
          {:ok, ackIds}
      end
  end
end
