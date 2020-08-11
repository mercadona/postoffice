defmodule Postoffice.Handlers.Pubsub do
  use Task

  require Logger

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Messaging

  def run(publisher, pending_messages) do
    messages = Enum.reduce(pending_messages, [], fn pm, acc -> [pm.message | acc] end)
    messages_ids = Enum.reduce(messages, [], fn m, acc -> [m.id | acc] end)

    Logger.info("Processing pubsub message",
      messages_ids: messages_ids,
      target: publisher.target
    )

    case impl().publish(publisher, messages) do
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

        pending_messages_ids = Enum.reduce(pending_messages, [], fn pm, acc -> [pm.id | acc] end)
        cache_failed_message(publisher, pending_messages_ids)

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end

  defp cache_failed_message(publisher, pending_messages_ids) do
    values =
      Enum.map(pending_messages_ids, fn pending_message_id ->
        {{publisher.id, pending_message_id}, 1}
      end)

    Phoenix.PubSub.broadcast(
      Postoffice.PubSub,
      "messages",
      {:message_failure, {values, publisher.seconds_retry}}
    )
  end
end
