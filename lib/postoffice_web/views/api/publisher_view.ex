defmodule PostofficeWeb.Api.PublisherView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.PublisherView

  def render("show.json", %{publisher: publisher}) do
    %{data: render_one(publisher, PublisherView, "publisher.json")}
  end

  def render("error.json", %{error: error}) do
    %{data: %{errors: error}}
  end

  def render("publisher.json", %{}) do
    %{}
  end

  def render("error.json", %{changeset: changeset}) do
    %{data: %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}}
  end

  def render("error.json", %{publisher: publisher_changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(publisher_changeset, &translate_error/1)
    }
  end
end
