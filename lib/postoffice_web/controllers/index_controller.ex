defmodule PostofficeWeb.IndexController do
  use PostofficeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      topics: Postoffice.count_topics(),
      messages_received: Postoffice.estimated_messages_count(),
      messages_published: Postoffice.estimated_published_messages_count(),
      publishers_failures: Postoffice.count_publishers_failures(),
      publishers: Postoffice.count_publishers()
    )
  end
end
