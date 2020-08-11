defmodule Postoffice.Handlers.Http do
  use Task
  require Logger

  alias Postoffice.Messaging
  alias Postoffice.PubSub

  def run(publisher, pending_message) do
    message = pending_message.message
    Logger.info("Processing http message", message_id: message.id, target: publisher.target)

    case impl().publish(publisher, message) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}}
      when status_code in 200..299 ->
        Logger.info("Succesfully sent http message",
          message_id: message.id,
          target: publisher.target
        )

        {:ok, _} =
          Messaging.mark_message_as_delivered(%{
            publisher_id: publisher.id,
            message_id: message.id
          })

        {:ok, :sent}

      {:ok, response} ->
        error_reason =
          "Error trying to process message from HttpConsumer with status_code: #{
            response.status_code
          }"

        Logger.info(error_reason)

        cache_failed_message(publisher, pending_message)

        Messaging.create_publisher_failure(%{
          publisher_id: publisher.id,
          message_id: message.id,
          reason: error_reason
        })

        {:error, :nosent}

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_reason = "Error trying to process message from HttpConsumer: #{reason}"
        Logger.info(error_reason)

        cache_failed_message(publisher, pending_message)

        Messaging.create_publisher_failure(%{
          publisher_id: publisher.id,
          message_id: message.id,
          reason: error_reason
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :http_consumer_impl, Postoffice.Adapters.Http)
  end

  defp cache_failed_message(publisher, pending_message) do
    Phoenix.PubSub.broadcast(
      Postoffice.PubSub,
      "messages",
      {:message_failure, {publisher.id, pending_message.id, publisher.seconds_retry}}
    )
  end
end
