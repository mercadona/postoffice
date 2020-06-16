defmodule PostofficeWeb.Api.BulkMessageController do
  use PostofficeWeb, :controller

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, message_params) do
    case Postoffice.receive_messages(message_params) do
      {:ok, _res} ->
        conn
        |> put_status(:created)
        |> render("show.json")
      {:error, _reason} ->
        conn
        |> put_status(:not_acceptable)
        |> render("error.json", error: "Not all messages were inserted")
    end
  end
end
