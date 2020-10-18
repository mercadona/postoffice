defmodule PostofficeWeb.Api.BulkMessageController do
  use PostofficeWeb, :controller

  action_fallback PostofficeWeb.Api.FallbackController

  alias Postoffice

  def create(conn, message_params) do
    case Postoffice.add_messages_to_deliver(message_params) do
      {:ok, ids} ->
        conn
        |> put_status(:created)
        |> render("show.json", message_ids: ids)

      {:error, reason} ->
        conn
        |> put_status(:not_acceptable)
        |> render("error.json", error: reason)
    end
  end
end
