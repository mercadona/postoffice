defmodule PostofficeWeb.Api.TopicController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Topic

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, topic_params) do
    ramon = Map.put_new(topic_params, "origin_host", "example.com")
    with {:ok, %Topic{} = topic} <- Postoffice.create_topic(ramon) do
      conn
      |> put_status(:created)
      |> render("show.json", topic: topic)
  end
end
