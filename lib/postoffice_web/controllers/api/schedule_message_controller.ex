defmodule PostofficeWeb.Api.ScheduleMessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, message_params) do
    with {:ok, id} <- Messaging.schedule_message(message_params) do
      conn
      |> put_status(:created)
      |> render("message.json", message_id: id)
    end
  end
end
