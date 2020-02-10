defmodule PostofficeWeb.IndexController do
  use PostofficeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      topics: Postoffice.count_topics(),
      messages_received: Postoffice.count_received_messages(),
      messages_published: Postoffice.count_published_messages(),
      publishers_failures: Postoffice.count_publishers_failures(),
      publishers: Postoffice.count_publishers()
    )
  end
end
