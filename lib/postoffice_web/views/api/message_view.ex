defmodule PostofficeWeb.Api.MessageView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.MessageView

  def render("index.json", %{messages: messages}) do
    %{data: render_many(messages, MessageView, "message.json")}
  end

  def render("show.json", %{message_id: message_id}) do
    %{data: render_one(message_id, MessageView, "message.json")}
  end

  def render("message.json", %{message_id: message_id}) do
    %{
      id: message_id
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{data: render_one(changeset, MessageView, "error.json")}
  end

  def render("error.json", %{error: error}) do
    %{data: %{errors: error}}
  end

  def render("error.json", %{message: message_changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(message_changeset, &translate_error/1)
    }
  end
end
