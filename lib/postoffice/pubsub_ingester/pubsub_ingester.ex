defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(%{sub: sub_name} = subscription_to_topic) do
    conn = PubSubClient.connect()
    PubSubClient.get(conn, subscription_to_topic)
    |> case do
      {:ok, messages} ->
        ingest_messages({:ok, messages})
        |> confirm(conn, sub_name)

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

  defp confirm({:ok, []}, _conn, _sub_name), do: {:ok, []}

  defp confirm(ackIds, conn, sub_name), do: PubSubClient.confirm(conn, sub_name, ackIds)
end
