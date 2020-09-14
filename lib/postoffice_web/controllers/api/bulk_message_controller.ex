defmodule PostofficeWeb.Api.BulkMessageController do
  use PostofficeWeb, :controller

  action_fallback PostofficeWeb.Api.FallbackController

  alias Postoffice.Messaging

  def create(conn, message_params) do
    case Messaging.add_messages_to_deliver(message_params) do
      {:ok, ids} ->
        conn
        |> put_status(:created)
        |> render("show.json", message_ids: ids)

      {:error, _reason} ->
        conn
        |> put_status(:not_acceptable)
        |> render("error.json", error: "Not all messages were inserted")
    end
  end
end
