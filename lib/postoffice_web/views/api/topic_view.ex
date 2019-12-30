defmodule PostofficeWeb.Api.TopicView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.TopicView

  def render("show.json", %{topic: topic}) do
    %{data: render_one(topic, TopicView, "topic.json")}
  end

  def render("topic.json", %{topic: topic}) do
    %{
      id: topic.id,
      name: topic.name
    }
  end
end
