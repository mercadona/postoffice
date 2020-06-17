defmodule Postoffice.Handlers.Pubsub do
  use Task

  require Logger

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Messaging

  def run(publisher, message) do
    messages_ids = Enum.reduce(message, [], fn m, acc -> [m.id | acc] end)

    Logger.info("Processing pubsub message",
      messages_ids: messages_ids,
      target: publisher.target
    )

    case impl().publish(publisher, message) do
      {:ok, _response = %PublishResponse{}} ->
        Logger.info("Succesfully sent pubsub message",
          target: publisher.target
        )

        {:ok, _} =
          Messaging.mark_message_as_delivered(%{
            publisher_id: publisher.id,
            message_id: messages_ids
          })

        {:ok, :sent}

      {:error, error} ->
        error_reason = "Error trying to process message from PubsubConsumer: #{error}"
        Logger.info(error_reason)

        Messaging.create_publisher_failure(%{
          publisher_id: publisher.id,
          message_id: messages_ids,
          reason: error_reason
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end
end
