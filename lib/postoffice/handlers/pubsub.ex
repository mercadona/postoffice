defmodule Postoffice.Handlers.Pubsub do
  use Task

  require Logger

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Messaging

  @spec run(any, any, any) :: {:error, :nosent} | {:ok, :sent}
  def run(publisher_target, publisher_id, message) do
    Logger.info("Processing pubsub message", message_id: message.public_id, target: publisher_target)

    case impl().publish(publisher_target, message) do
      {:ok, _response = %PublishResponse{}} ->
        Logger.info("Succesfully sent pubsub message", message_id: message.public_id, target: publisher_target)

        {:ok, _} =
          Messaging.mark_message_as_delivered(%{
            publisher_id: publisher_id,
            message_id: message.id
          })

        {:ok, :sent}

      {:error, error} ->
        error_reason = "Error trying to process message from PubsubConsumer: #{error}"
        Logger.info(error_reason)

        Messaging.create_publisher_failure(%{
          publisher_id: publisher_id,
          message_id: message.id,
          reason: error_reason
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end
end
