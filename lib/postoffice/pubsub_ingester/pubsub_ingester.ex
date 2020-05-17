defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(subscription_to_topic) do
    ackIds = case PubSubClient.get(subscription_to_topic) do
      {:ok, messages} ->
        Enum.map(messages, fn message ->
          {:ok, _message} = Postoffice.receive_message(message)
          message["ackId"]
        end)
    end
    PubSubClient.confirm(ackIds)
  end
end
