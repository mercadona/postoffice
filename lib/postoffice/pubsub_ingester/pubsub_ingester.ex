defmodule Postoffice.PubSubIngester.PubSubIngester do
  alias Postoffice.PubSubIngester.PubSubClient

  def run(subscription_to_topic) do
    case PubSubClient.get(subscription_to_topic) do
      {:ok, messages} ->
        Enum.each(messages, fn message ->
          {:ok, _message} = Postoffice.receive_message(message)
          {:ok}
        end)
    end
    # los confirmamos
    # PubSubClient.confirm(messages)
  end
end
