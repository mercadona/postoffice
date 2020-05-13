defmodule PostofficeWeb.IndexController do
  use PostofficeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      page_name: "Dashboard",
      topics: Postoffice.count_topics(),
      messages_received: Postoffice.estimated_messages_count(),
      messages_published: Postoffice.estimated_published_messages_count(),
      publishers_failures: Postoffice.count_publishers_failures(),
      publishers: Postoffice.count_publishers(),
      pending_messages: Postoffice.count_pending_messages()
    )
  end
end
