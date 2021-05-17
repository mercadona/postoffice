defmodule PostofficeWeb.MessageController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.Messaging.MessageSearchParams
  alias Postoffice.HistoricalData

  def index(
        %{params: %{"topic" => topic}} = conn,
        %{"page" => page, "page_size" => page_size})
      when topic != "" do
    messages =
      %MessageSearchParams{
        topic: topic,
        page: page,
        page_size: page_size
      }
      |> Messaging.get_failing_messages()

    render(conn, "index.html",
      page_name: "Messages",
      messages: messages.entries,
      page_number: messages.page_number,
      total_pages: messages.total_pages,
      topic: topic
    )
  end

  def index(conn, %{"page" => page, "page_size" => page_size}) do
    messages =
      %MessageSearchParams{
        topic: "",
        page: page,
        page_size: page_size
      }
      |> Messaging.get_failing_messages()

    render(conn, "index.html",
      page_name: "Messages",
      messages: messages.entries,
      page_number: messages.page_number,
      total_pages: messages.total_pages,
      topic: ""
    )
  end

  def index(conn, %{"page" => page, "page_size" => page_size} = params) do
    messages = Messaging.get_failing_messages(params)

    render(conn, "index.html",
      page_name: "Messages",
      messages: messages.entries,
      page_number: messages.page_number,
      total_pages: messages.total_pages,
      topic: ""
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
