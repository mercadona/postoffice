defmodule Postoffice.Adapters.Http do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(endpoint, message) do
    Logger.info("Dispatching Http message to #{endpoint}")
    %{payload: payload} = message

    case HTTPoison.post(endpoint, Poison.encode!(payload), [
           {"content-type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}} when status_code in 200..299 ->
        {:ok, message}

      {:ok, response} ->
        {:error, response.status_code}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
