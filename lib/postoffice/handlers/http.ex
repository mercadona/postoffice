defmodule Postoffice.Handlers.Http do
  use Task
  require Logger

  alias Postoffice.Messaging

  def run(publisher_target, publisher_id, message) do
    case impl().publish(publisher_target, message) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}}
      when status_code in 200..299 ->
        Logger.info("Succesfully sent http message to #{publisher_target}")

        {:ok, _} =
          Messaging.create_publisher_success(%{
            publisher_id: publisher_id,
            message_id: message.id
          })

        {:ok, :sent}

      {:ok, response} ->
        Logger.info("Error trying to process message from HttpConsumer #{response.status_code}")

        Messaging.create_publisher_failure(%{
          publisher_id: publisher_id,
          message_id: message.id
        })

        {:error, :nosent}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info("Error trying to process message from HttpConsumer #{reason}")

        Messaging.create_publisher_failure(%{
          publisher_id: publisher_id,
          message_id: message.id
        })

        {:error, :nosent}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :http_consumer_impl, Postoffice.Adapters.Http)
  end
end
