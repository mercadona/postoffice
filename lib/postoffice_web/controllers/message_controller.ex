defmodule PostofficeWeb.MessageController do
  use PostofficeWeb, :controller

  def index(conn, %{"uuid" => uuid}) do
    case Postoffice.find_message_by_uuid(uuid) do
      nil ->
        conn
        |> put_flash(:info, "Message not found")
        |> redirect(to: Routes.publisher_path(conn, :index))

      message ->
        conn
        |> redirect(to: Routes.message_path(conn, :show, message.id))
    end
  end

  def show(conn, %{"id" => id}) do
    message = Postoffice.get_message(id)
    message_success = Postoffice.get_message_success(id)
    message_failures = Postoffice.get_message_failures(id)

    render(conn, "show.html",
      message: message,
      message_success: message_success,
      message_failures: message_failures
    )
  end
end
