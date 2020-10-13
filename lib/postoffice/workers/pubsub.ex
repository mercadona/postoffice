defmodule Postoffice.Workers.Pubsub do
  require Logger

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.HistoricalData

  @snooze_seconds 30

  def run(id, %{"consumer_id" => consumer_id, "target" => target} = args) do
    Logger.info("Processing pubsub message",
      messages_ids: id,
      target: target
    )

    case check_publisher_active(consumer_id) do
      true ->
        publish(id, args)

      false ->
        Logger.info("Do not process task as publisher is disabled", publisher_id: consumer_id)
        {:snooze, @snooze_seconds}
    end
  end

  defp publish(
         id,
         %{
           "attributes" => attributes,
           "consumer_id" => consumer_id,
           "payload" => payload,
           "target" => target
         } = args
       ) do
    message_id = id || 0
    historical_payload = if not is_list(payload), do: [payload], else: payload

    case impl().publish(id, args) do
      {:ok, _response = %PublishResponse{}} ->
        Logger.info("Succesfully sent pubsub message",
          target: target
        )

        {:ok, _data} =
          HistoricalData.create_sent_messages(%{
            message_id: message_id,
            consumer_id: consumer_id,
            payload: historical_payload,
            attributes: attributes
          })

        {:ok, :sent}

      {:error, error} ->
        error_reason = "Error trying to process message from PubsubConsumer: #{error}"
        Logger.info(error_reason)

        {:ok, _data} =
          HistoricalData.create_failed_messages(%{
            message_id: message_id,
            consumer_id: consumer_id,
            payload: historical_payload,
            attributes: attributes,
            reason: error_reason
          })

        {:error, :nosent}
    end
  end

  defp check_publisher_active(publisher_id) do
    case Cachex.get(:postoffice, publisher_id) do
      {:ok, :disabled} ->
        false

      {:ok, nil} ->
        true
    end
  end

  defp impl do
    Application.get_env(:postoffice, :pubsub_consumer_impl, Postoffice.Adapters.Pubsub)
  end
end
