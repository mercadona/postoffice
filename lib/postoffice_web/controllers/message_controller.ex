defmodule PostofficeWeb.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.HistoricalData

  def index(conn, %{"id" => id}) do
    case Messaging.get_message!(id) do
      nil ->
        conn
        |> put_flash(:info, "Message not found")
        |> redirect(to: Routes.dashboard_path(conn, :index))

      message ->
        conn
        |> redirect(to: Routes.message_path(conn, :show, message.id))
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html",
      message: "message",
      message_success: HistoricalData.get_sent_messages!(id),
      message_failures: HistoricalData.get_failed_messages!(id),
      page_name: "Message detail"
    )
  end
end
