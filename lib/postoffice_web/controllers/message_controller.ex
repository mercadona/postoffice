defmodule PostofficeWeb.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.HistoricalData

  def index(conn, %{"page" => page, "page_size" => page_size} = params) do
    IO.inspect(params, label: "\nMi amigo el controlador")

    # messages = Messaging.get_failing_messages(%{page: String.to_integer(page), page_size: String.to_integer(page_size)})
    messages = Messaging.get_failing_messages(params)

    render(conn, "index.html",
      page_name: "Messages",
      messages: messages.entries,
      page_number: messages.page_number)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html",
      message: "message",
      message_success: HistoricalData.get_sent_message_by_message_id!(id),
      message_failures: HistoricalData.list_failed_messages_by_message_id(id),
      page_name: "Message detail"
    )
  end
end
