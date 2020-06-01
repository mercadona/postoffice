defmodule PostofficeWeb.Api.BulkMessageController do
  use PostofficeWeb, :controller

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, message_params) do
    inserted_messages =
      Enum.map(message_params["_json"], fn message -> Postoffice.receive_message(message) end)

    case Enum.all?(inserted_messages, fn {status, _message} -> status == :ok end) do
      true ->
        conn
        |> put_status(:created)
        |> render("show.json")

      false ->
        conn
        |> put_status(:not_acceptable)
        |> render("error.json", error: "Not all messages were inserted")
    end
  end
end
