defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(subscription_to_topic) do
    conn = PubSubClient.connect()
    PubSubClient.get(conn, subscription_to_topic)
    |> case do
      {:ok, messages} ->
        ingest_messages({:ok, messages})
        |> confirm(conn)

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

  defp confirm({:ok, []}, _conn), do: {:ok, []}

  defp confirm(ackIds, conn), do: PubSubClient.confirm(ackIds, conn)
end
