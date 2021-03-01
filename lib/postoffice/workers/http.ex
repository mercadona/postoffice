defmodule Postoffice.Workers.Http do
  require Logger

  alias Postoffice.HistoricalData

  @snooze_seconds 30

  def run(id, %{"consumer_id" => consumer_id, "target" => target} = args) do
    Logger.info("Processing http message",
      messages_ids: id,
      target: target
    )

    case check_publisher_state(consumer_id) do
      :active ->
        publish(id, args)

      :disabled ->
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
    historical_payload = if is_list(payload) == false, do: [payload], else: payload

    case impl().publish(id, args) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}}
      when status_code in 200..299 ->
        Logger.info("Succesfully sent http message",
          message_id: id,
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

      {:ok, response} ->
        error_reason =
          "Error trying to process message from HttpConsumer with status_code: #{
            response.status_code
          }"

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

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_reason = "Error trying to process message from HttpConsumer: #{reason}"
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

  defp check_publisher_state(publisher_id) do
    case Cachex.get(:postoffice, publisher_id) do
      {:ok, :disabled} ->
        :disabled

      {:ok, nil} ->
        :active
    end
  end

  defp impl do
    Application.get_env(:postoffice, :http_consumer_impl, Postoffice.Adapters.Http)
  end
end
