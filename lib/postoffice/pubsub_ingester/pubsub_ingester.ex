defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(subscription_to_topic) do
    PubSubClient.get(subscription_to_topic)
    |> case do
      {:ok, messages} ->
        ingest_messages({:ok, messages})
        |> confirm

      error ->
        error
    end
  end

  defp ingest_messages({:ok, []} = response), do: response

  defp ingest_messages({:ok, messages}) do
    Enum.map(messages, fn message ->
      {:ok, _message} = Postoffice.receive_message(message)
      message["ackId"]
    end)
  end

  defp confirm({:ok, []} = response), do: response

  defp confirm(ackIds), do: PubSubClient.confirm(ackIds)
end
