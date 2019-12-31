defmodule PostofficeWeb.Api.TopicView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.TopicView

  def render("show.json", %{topic: topic}) do
    %{data: render_one(topic, TopicView, "topic.json")}
  end

  def render("show.json", %{changeset: changeset}) do
    %{data: render_one(changeset, TopicView, "error.json")}
  end

  def render("topic.json", %{topic: topic}) do
    %{
      id: topic.id,
      name: topic.name
    }
  end

  def render("error.json", %{topic: topic_changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(topic_changeset, &translate_error/1)
    }
  end
end
