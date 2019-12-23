defmodule Postoffice.Handlers.Pubsub do
  use Task

  require Logger

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Message

  def run(publisher_endpoint, publisher_id, message) do
    case impl().publish(publisher_endpoint, message) do
      {:ok, message = %Message{}} ->
        {:ok, _} =
          Messaging.create_publisher_success(%{
            publisher_id: publisher_id,
            message_id: message.id
          })

        {:ok, :sent}

      {:ok, status_code} ->
        Logger.info("Http handler failed to process message, response code #{status_code}")

        Messaging.create_publisher_failure(%{
          publisher_id: publisher_id,
          message_id: message.id
        })

        {:error, :nosent}

      {:error, error} ->
        Logger.info("Error trying to process message from HttpConsumer #{error}")

        Messaging.create_publisher_failure(%{
          publisher_id: publisher_id,
          message_id: message.id
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end
end
