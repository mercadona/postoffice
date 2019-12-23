defmodule PostofficeWeb.PageController do
  use PostofficeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
