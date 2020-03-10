defmodule Postoffice.Rescuer.Client do
  require Logger

  alias Postoffice.Rescuer.Adapters.Http

  def list(host) do
    case impl().list(host) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        Logger.info("Succesfully listed pending messages from #{host}")
        {:ok, Poison.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.info(
          "Non successful response list pending messages from #{host} with status code: #{
            status_code
          }"
        )

        {:error, []}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info("Error trying to list pending messages #{reason}")
        {:error, []}
    end
  end

  def delete(host, message_id) do
    case impl().delete(host, message_id) do
      {:ok, %HTTPoison.Response{status_code: status_code}}
      when status_code in 200..299 ->
        Logger.info("Successfully deleted message #{message_id} from #{host}")
        {:ok, :deleted}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.info(
          "Non successful response deleting message from #{host} with status code: #{
            status_code
          }"
        )

        {:error, "Request status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info("Error trying to delete message #{host}: #{reason}")
        {:error, reason}
    end
  end

  defp impl do
    Application.get_env(:postoffice, :rescuer_client, Http)
  end
end
