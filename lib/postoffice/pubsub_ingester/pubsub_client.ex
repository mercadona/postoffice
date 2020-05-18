defmodule Postoffice.PubSubIngester.PubSubClient do
  alias Postoffice.PubSubIngester.Adapters.PubSub

  def get(%{topic: topic_name, sub: sub_name}) do
    impl().get(sub_name)
    |> case do
      {:ok, response} ->
        response.receivedMessages
        |> build_messages(topic_name)
      error ->
        error
    end
  end

  defp build_messages(receivedMessages, _topic_name) when receivedMessages == nil do
    {:ok, []}
  end

  defp build_messages(receivedMessages, topic_name) when receivedMessages != nil do
    messages =
      Enum.map(receivedMessages, fn message ->
        payload =
          message.message.data
          |> Base.decode64!()
          |> Poison.decode!()

        attributes = message.message.attributes || %{}
        ackId = message.ackId

        %{
          "payload" => payload,
          "attributes" => attributes,
          "topic" => topic_name,
          "ackId" => ackId
        }
      end)

    {:ok, messages}
  end

  def confirm(ackIds) do
    impl().confirm(ackIds)
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_ingester_client, PubSub)
  end
end
