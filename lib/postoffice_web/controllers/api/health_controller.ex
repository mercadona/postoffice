defmodule PostofficeWeb.Api.HealthController do
  use PostofficeWeb, :controller

  def index(conn, _params) do
    case Postoffice.ping() do
      :ok ->
        render(conn, "index.json", health_status: "ok")

      :ko ->
        render(conn, "index.json", health_status: "ko")
    end
  end
end
