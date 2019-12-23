defmodule PostofficeWeb.Api.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Message

  action_fallback PostofficeWeb.FallbackController

  def index(conn, _params) do
    messages = Messaging.list_messages()
    render(conn, "index.json", messages: messages)
  end

  def create(conn, %{"message" => message_params}) do
    with {:ok, %Message{} = message} <- Postoffice.receive_message(message_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.message_path(conn, :show, message))
      |> render("show.json", message: message)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Messaging.get_message!(id)
    render(conn, "show.json", message: message)
  end
end
