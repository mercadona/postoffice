defmodule PostofficeWeb.Api.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Message

  action_fallback PostofficeWeb.FallbackController

  def create(conn, %{"message" => message_params}) do
    with {:ok, %Message{} = message} <- Postoffice.receive_message(message_params) do
      conn
      |> put_status(:created)
      |> render("show.json", message: message)
    end
  end
end
