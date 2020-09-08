defmodule Postoffice.Workers.Pubsub do
  require Logger

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.HistoricalData

  def run(id, %{
    "attributes" => attributes,
    "consumer_id" => consumer_id,
    "payload" => payload,
    "target" => target
  } = args) do
    Logger.info("Processing pubsub message",
      messages_ids: id,
      target: target
    )
    message_id = id || 0

    case impl().publish(id, args) do
      {:ok, _response = %PublishResponse{}} ->
        Logger.info("Succesfully sent pubsub message",
          target: target
        )

        {:ok, _data} = HistoricalData.create_sent_messages(%{
          message_id: message_id,
          consumer_id: consumer_id,
          payload: payload,
          attributes: attributes
        })

        {:ok, :sent}

      {:error, error} ->
        error_reason = "Error trying to process message from PubsubConsumer: #{error}"
        Logger.info(error_reason)

        HistoricalData.create_failed_messages(%{
          message_id: message_id,
          consumer_id: consumer_id,
          payload: payload,
          attributes: attributes,
          reason: error_reason
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end
end
