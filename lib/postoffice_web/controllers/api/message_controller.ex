defmodule PostofficeWeb.Api.MessageController do
  use PostofficeWeb, :controller

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, message_params) do
    with {:ok, id} <- Postoffice.receive_message(message_params) do
      conn
      |> put_status(:created)
      |> render("message.json", message_id: id)
    end
  end
end
