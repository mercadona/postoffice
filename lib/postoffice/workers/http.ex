defmodule Postoffice.Workers.Http do
  require Logger

  alias Postoffice.HistoricalData

  def run(
        id,
        %{
          "attributes" => attributes,
          "consumer_id" => consumer_id,
          "payload" => payload,
          "target" => target
        } = args
      ) do
    message_id = id || 0

    case impl().publish(id, args) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}}
      when status_code in 200..299 ->
        Logger.info("Succesfully sent http message",
          message_id: id,
          target: target
        )

        HistoricalData.create_sent_messages(%{
          message_id: message_id,
          consumer_id: consumer_id,
          payload: payload,
          attributes: attributes
        })

        {:ok, :sent}

      {:ok, response} ->
        error_reason =
          "Error trying to process message from HttpConsumer with status_code: #{
            response.status_code
          }"

        Logger.info(error_reason)

        HistoricalData.create_failed_messages(%{
          message_id: message_id,
          consumer_id: consumer_id,
          payload: payload,
          attributes: attributes,
          reason: error_reason
        })

        {:error, :nosent}

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_reason = "Error trying to process message from HttpConsumer: #{reason}"
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
    Application.get_env(:postoffice, :http_consumer_impl, Postoffice.Adapters.Http)
  end
end
