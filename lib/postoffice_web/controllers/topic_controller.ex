defmodule PostofficeWeb.TopicController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Topic

  def index(conn, _params) do
    topics = Messaging.list_topics()
    render(conn, "index.html", topics: topics, page_name: "Topics")
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"topic" => topic_params}) do
    {:ok, topic} = Postoffice.create_topic(topic_params)

    conn
    |> put_flash(:info, "Topic #{topic.id} created!")
    |> redirect(to: Routes.topic_path(conn, :index))
  end
end
