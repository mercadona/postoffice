defmodule PostofficeWeb.Api.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Message

  action_fallback PostofficeWeb.FallbackController

  def create(conn, message_params) do
    case Postoffice.receive_message_final(message_params) do
      {:ok, message} ->
        conn
        |> put_status(:created)
        |> render("show.json", message: message)

      {:topic_not_found, {}} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: %{topic: ["is invalid"]})

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("show.json", changeset: changeset)
    end
  end
end
