defmodule PostofficeWeb.IndexController do
  use PostofficeWeb, :controller

  alias Number.Delimit

  def index(conn, _params) do
    render(conn, "index.html",
      page_name: "Dashboard",
      topics: Delimit.number_to_delimited(Postoffice.count_topics(), precision: 0),
      messages_received: Delimit.number_to_delimited(Postoffice.estimated_messages_count(), precision: 0),
      messages_published: Delimit.number_to_delimited(Postoffice.estimated_published_messages_count(), precision: 0),
      publishers_failures: Delimit.number_to_delimited(Postoffice.count_publishers_failures(), precision: 0),
      publishers: Delimit.number_to_delimited(Postoffice.count_publishers(), precision: 0),
      pending_messages: Delimit.number_to_delimited(Postoffice.count_pending_messages(), precision: 0)
    )
  end
end
