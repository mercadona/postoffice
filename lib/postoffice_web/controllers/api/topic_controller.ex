defmodule PostofficeWeb.Api.TopicController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Topic

  action_fallback PostofficeWeb.FallbackController

  def create(conn, topic_params) do
    case Postoffice.create_topic(topic_params) do
      {:ok, topic} ->
        conn
        |> put_status(:created)
        |> render("show.json", topic: topic)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("show.json", changeset: changeset)
    end
  end
end
