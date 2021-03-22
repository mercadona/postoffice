defmodule PostofficeWeb.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.HistoricalData

  def index(conn, %{"page" => page, "page_size" => page_size} = params) do
    messages = Messaging.get_failing_messages(params)

    render(conn, "index.html",
      page_name: "Messages",
      messages: messages.entries,
      page_number: messages.page_number,
      total_pages: messages.total_pages
    )
  end

  def index(conn, %{}) do
    index(conn, %{"page" => 1, "page_size" => 100})
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
