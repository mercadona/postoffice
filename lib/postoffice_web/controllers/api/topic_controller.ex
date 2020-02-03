defmodule PostofficeWeb.Api.TopicController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Topic

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, topic_params) do
    with {:ok, %Topic{} = topic} <- Postoffice.create_topic(topic_params) do
      conn
      |> put_status(:created)
      |> render("show.json", topic: topic)
    end
  end
end
