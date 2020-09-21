defmodule PostofficeWeb.IndexController do
  use PostofficeWeb, :controller

  alias Number.Delimit
  alias Postoffice.Messaging

  def index(conn, _params) do
    render(conn, "index.html",
      page_name: "Dashboard",
      topics: Delimit.number_to_delimited(Messaging.count_topics(), precision: 0),
      messages_received:
        Delimit.number_to_delimited(Messaging.get_estimated_count("messages"), precision: 0),
      messages_published:
        Delimit.number_to_delimited(Messaging.get_estimated_count("publisher_success"),
          precision: 0
        ),
      publishers_failures:
        Delimit.number_to_delimited(Messaging.count_failing_jobs(), precision: 0),
      publishers: Delimit.number_to_delimited(Messaging.count_publishers(), precision: 0),
      pending_messages:
        Delimit.number_to_delimited(Messaging.count_pending_messages(), precision: 0)
    )
  end
end
